#!/usr/bin/env python3
"""CP-SAT based schedule solver."""

from __future__ import annotations

import argparse
import json
import sys
from collections import defaultdict
from dataclasses import dataclass
from datetime import date, datetime, timedelta
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional, Tuple

from ortools.sat.python import cp_model


# ---------------------------------------------------------------------------
# Data containers
# ---------------------------------------------------------------------------


@dataclass
class TimeSlot:
    slot_id: int
    order: int


@dataclass
class Audience:
    audience_id: int
    capacity: int
    preferred_teacher_id: Optional[int]


@dataclass
class Assignment:
    assignment_id: int
    group_id: int
    teacher_id: int
    discipline_id: int
    lesson_type_id: int
    total_pairs: int
    start: date
    end: date
    subgroup: Optional[str]
    remaining_pairs: int


@dataclass
class ExistingLesson:
    group_id: int
    teacher_id: int
    audience_id: int
    discipline_id: int
    lesson_type_id: int
    lesson_date: date
    slot_id: int
    subgroup: Optional[str]


@dataclass
class Option:
    session_index: int
    option_index: int
    assignment_id: int
    group_id: int
    teacher_id: int
    audience_id: int
    discipline_id: int
    lesson_type_id: int
    lesson_date: date
    slot_id: int
    slot_order: int
    subgroup: Optional[str]


# ---------------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------------


def parse_args(argv: List[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="CP-SAT schedule solver")
    parser.add_argument("--request", required=True, type=Path, help="ScheduleRequest JSON")
    parser.add_argument("--output", type=Path, help="Where to write ScheduleSolution JSON")
    parser.add_argument("--verbose", action="store_true", help="Print diagnostics to stderr")
    return parser.parse_args(argv)


def parse_iso_date(value: str) -> date:
    return datetime.fromisoformat(value).date()


def daterange(start: date, end: date) -> Iterable[date]:
    current = start
    while current <= end:
        yield current
        current += timedelta(days=1)


def is_practice(name: str) -> bool:
    lowered = name.lower()
    return "практ" in lowered or "practice" in lowered


def load_request(path: Path) -> Dict[str, Any]:
    with path.open("r", encoding="utf-8") as fp:
        return json.load(fp)


# ---------------------------------------------------------------------------
# Solver
# ---------------------------------------------------------------------------


def build_solution(request: Dict[str, Any], verbose: bool = False) -> Dict[str, Any]:
    period_start = parse_iso_date(request["period"]["startDate"])
    period_end = parse_iso_date(request["period"]["endDate"])

    # Time slots
    time_slots = [
        TimeSlot(slot_id=slot["id"], order=slot["order"])
        for slot in request.get("timeSlots", [])
    ]
    slot_by_id = {slot.slot_id: slot for slot in time_slots}

    # Lesson types
    lesson_type_name: Dict[int, str] = {}
    practice_type_ids: set[int] = set()
    for lt in request.get("lessonTypes", []):
        lt_id = lt["id"]
        name = lt.get("name", "")
        lesson_type_name[lt_id] = name
        if is_practice(name):
            practice_type_ids.add(lt_id)

    # Groups
    group_sizes = {g["id"]: g.get("size") or 0 for g in request.get("groups", [])}

    # Teachers
    teacher_names = {t["id"]: t.get("name", "") for t in request.get("teachers", [])}

    # Audiences
    audiences = {
        a["id"]: Audience(
            audience_id=a["id"],
            capacity=a.get("capacity") or 0,
            preferred_teacher_id=a.get("preferredTeacherId"),
        )
        for a in request.get("audiences", [])
    }

    # Audience -> allowed lesson types
    audience_allowed: Dict[int, set[int]] = defaultdict(set)
    for mapping in request.get("audienceLessonTypes", []):
        audience_allowed[mapping["audienceId"]].add(mapping["lessonTypeId"])

    # Existing lessons occupy slots immediately
    existing_lessons: List[ExistingLesson] = []
    group_slot_busy: Dict[Tuple[int, date, int], int] = defaultdict(int)
    teacher_slot_busy: Dict[Tuple[int, date, int], int] = defaultdict(int)
    audience_slot_busy: Dict[Tuple[int, date, int], int] = defaultdict(int)
    group_day_load: Dict[Tuple[int, date], int] = defaultdict(int)
    teacher_day_load: Dict[Tuple[int, date], int] = defaultdict(int)

    for lesson in request.get("existingLessons", []):
        lesson_date = parse_iso_date(lesson["date"])
        slot_id = lesson["slotId"]
        slot = slot_by_id.get(slot_id)
        if slot is None:
            continue
        existing_lessons.append(
            ExistingLesson(
                group_id=lesson["groupId"],
                teacher_id=lesson["teacherId"],
                audience_id=lesson["audienceId"],
                discipline_id=lesson["disciplineId"],
                lesson_type_id=lesson.get("lessonTypeId") or 0,
                lesson_date=lesson_date,
                slot_id=slot_id,
                subgroup=lesson.get("subgroup"),
            )
        )
        group_slot_busy[(lesson["groupId"], lesson_date, slot.order)] += 1
        teacher_slot_busy[(lesson["teacherId"], lesson_date, slot.order)] += 1
        audience_slot_busy[(lesson["audienceId"], lesson_date, slot.order)] += 1
        group_day_load[(lesson["groupId"], lesson_date)] += 1
        teacher_day_load[(lesson["teacherId"], lesson_date)] += 1

    # Assignments and remaining demand
    assignments: Dict[int, Assignment] = {}
    for payload in request.get("groupAssignments", []):
        total_hours = payload.get("totalHours") or 0
        hours_per = payload.get("hoursPerLesson") or 2
        total_pairs = (total_hours + hours_per - 1) // hours_per
        if total_pairs <= 0:
            continue
        start = max(parse_iso_date(payload.get("startDate") or request["period"]["startDate"]), period_start)
        end = min(parse_iso_date(payload.get("endDate") or request["period"]["endDate"]), period_end)
        if end < start:
            continue

        # subtract existing lessons matching this assignment
        existing_count = sum(
            1
            for lesson in existing_lessons
            if lesson.group_id == payload["groupId"]
            and lesson.teacher_id == payload["teacherId"]
            and lesson.discipline_id == payload["disciplineId"]
            and lesson.lesson_type_id == (payload.get("lessonTypeId") or 0)
        )
        remaining = max(0, total_pairs - existing_count)
        if remaining == 0:
            continue

        assignment = Assignment(
            assignment_id=payload["id"],
            group_id=payload["groupId"],
            teacher_id=payload["teacherId"],
            discipline_id=payload["disciplineId"],
            lesson_type_id=payload.get("lessonTypeId") or 0,
            total_pairs=total_pairs,
            start=start,
            end=end,
            subgroup=payload.get("subgroup"),
            remaining_pairs=remaining,
        )
        assignments[assignment.assignment_id] = assignment

    if not assignments:
        # Only existing lessons
        return {
            "lessons": [
                {
                    "assignmentId": 0,
                    "groupId": lesson.group_id,
                    "teacherId": lesson.teacher_id,
                    "audienceId": lesson.audience_id,
                    "disciplineId": lesson.discipline_id,
                    "lessonTypeId": lesson.lesson_type_id,
                    "date": lesson.lesson_date.isoformat(),
                    "slotId": lesson.slot_id,
                    "subgroup": lesson.subgroup,
                }
                for lesson in existing_lessons
            ],
            "objectiveScore": 0,
            "solverStats": {
                "status": "EXISTING_ONLY",
                "solveTimeSec": 0,
                "iterations": 0,
            },
        }

    # Allowed placements for sessions
    all_dates = list(daterange(period_start, period_end))

    def allowed_day_indexes(lt_id: int) -> set[int]:
        if lt_id in practice_type_ids:
            return set(range(6))  # Mon..Sat
        return set(range(5))  # Mon..Fri

    session_options: List[Option] = []
    session_to_options: Dict[int, List[Option]] = defaultdict(list)
    option_vars: Dict[Tuple[int, int], cp_model.BoolVar] = {}

    # Prepare model
    model = cp_model.CpModel()

    next_session_index = 0

    for assignment in assignments.values():
        allowed_days = allowed_day_indexes(assignment.lesson_type_id)
        group_size = group_sizes.get(assignment.group_id, 0)
        candidate_audiences = [
            aud_id
            for aud_id, aud in audiences.items()
            if aud.capacity >= group_size
            and (
                not audience_allowed[aud_id]
                or assignment.lesson_type_id in audience_allowed[aud_id]
            )
        ]
        if not candidate_audiences:
            raise RuntimeError(
                f"No suitable audiences for assignment {assignment.assignment_id}"
            )

        session_indices = list(range(next_session_index, next_session_index + assignment.remaining_pairs))
        next_session_index += assignment.remaining_pairs

        options_for_session: Dict[int, List[Option]] = {idx: [] for idx in session_indices}

        possible_options: List[Tuple[int, Option]] = []
        option_counter = 0
        for dt in all_dates:
            if dt < assignment.start or dt > assignment.end:
                continue
            weekday = dt.weekday()
            if weekday >= 6 or weekday not in allowed_days:
                continue
            for slot in time_slots:
                if (assignment.group_id, dt, slot.order) in group_slot_busy:
                    continue
                if (assignment.teacher_id, dt, slot.order) in teacher_slot_busy:
                    continue
                for aud_id in candidate_audiences:
                    if (aud_id, dt, slot.order) in audience_slot_busy:
                        continue
                    option = Option(
                        session_index=-1,  # to be assigned below
                        option_index=option_counter,
                        assignment_id=assignment.assignment_id,
                        group_id=assignment.group_id,
                        teacher_id=assignment.teacher_id,
                        audience_id=aud_id,
                        discipline_id=assignment.discipline_id,
                        lesson_type_id=assignment.lesson_type_id,
                        lesson_date=dt,
                        slot_id=slot.slot_id,
                        slot_order=slot.order,
                        subgroup=assignment.subgroup,
                    )
                    possible_options.append((option_counter, option))
                    option_counter += 1

        if len(possible_options) < assignment.remaining_pairs:
            raise RuntimeError(
                f"Недостаточно свободных слотов для заявки {assignment.assignment_id}"
            )

        # Distribute options across sessions evenly
        for idx, session_idx in enumerate(session_indices):
            count = 0
            for option_index, option in possible_options:
                opt = Option(
                    session_index=session_idx,
                    option_index=option_index,
                    assignment_id=option.assignment_id,
                    group_id=option.group_id,
                    teacher_id=option.teacher_id,
                    audience_id=option.audience_id,
                    discipline_id=option.discipline_id,
                    lesson_type_id=option.lesson_type_id,
                    lesson_date=option.lesson_date,
                    slot_id=option.slot_id,
                    slot_order=option.slot_order,
                    subgroup=option.subgroup,
                )
                options_for_session[session_idx].append(opt)
                session_options.append(opt)
                var = model.NewBoolVar(f"sess{session_idx}_opt{option_index}")
                option_vars[(session_idx, option_index)] = var
            if not options_for_session[session_idx]:
                raise RuntimeError(
                    f"Нет доступных вариантов для занятия заявки {assignment.assignment_id}"
                )

        for session_idx in session_indices:
            vars_for_session = [
                option_vars[(session_idx, opt.option_index)]
                for opt in options_for_session[session_idx]
            ]
            model.Add(sum(vars_for_session) == 1)
            session_to_options[session_idx] = options_for_session[session_idx]

    # Conflict constraints
    def add_limit(key_map: Dict[Tuple[Any, ...], List[cp_model.BoolVar]], limit_map: Dict[Tuple[Any, ...], int], base_limit: int):
        for key, vars_list in key_map.items():
            limit = base_limit
            if key in limit_map:
                limit -= limit_map[key]
            if limit < 0:
                limit = 0
            model.Add(sum(vars_list) <= limit)

    group_slot_vars: Dict[Tuple[int, date, int], List[cp_model.BoolVar]] = defaultdict(list)
    teacher_slot_vars: Dict[Tuple[int, date, int], List[cp_model.BoolVar]] = defaultdict(list)
    audience_slot_vars: Dict[Tuple[int, date, int], List[cp_model.BoolVar]] = defaultdict(list)
    group_day_vars: Dict[Tuple[int, date], List[cp_model.BoolVar]] = defaultdict(list)
    teacher_day_vars: Dict[Tuple[int, date], List[cp_model.BoolVar]] = defaultdict(list)

    for opt in session_options:
        var = option_vars[(opt.session_index, opt.option_index)]
        key = (opt.group_id, opt.lesson_date, opt.slot_order)
        group_slot_vars[key].append(var)
        key = (opt.teacher_id, opt.lesson_date, opt.slot_order)
        teacher_slot_vars[key].append(var)
        key = (opt.audience_id, opt.lesson_date, opt.slot_order)
        audience_slot_vars[key].append(var)
        group_day_vars[(opt.group_id, opt.lesson_date)].append(var)
        teacher_day_vars[(opt.teacher_id, opt.lesson_date)].append(var)

    for vars_list in group_slot_vars.values():
        model.Add(sum(vars_list) <= 1)
    for vars_list in teacher_slot_vars.values():
        model.Add(sum(vars_list) <= 1)
    for vars_list in audience_slot_vars.values():
        model.Add(sum(vars_list) <= 1)
    add_limit(group_day_vars, group_day_load, 6)
    add_limit(teacher_day_vars, teacher_day_load, 6)

    model.Minimize(0)

    solver = cp_model.CpSolver()
    solver.parameters.max_time_in_seconds = 15
    status = solver.Solve(model)
    if status not in (cp_model.OPTIMAL, cp_model.FEASIBLE):
        raise RuntimeError("Распределить пары не удалось. Попробуйте сократить период или ослабить ограничения.")

    scheduled: List[Dict[str, Any]] = []
    for session_idx, options in session_to_options.items():
        chosen = None
        for opt in options:
            var = option_vars[(opt.session_index, opt.option_index)]
            if solver.Value(var):
                chosen = opt
                break
        if chosen is None:
            continue
        scheduled.append(
            {
                "assignmentId": chosen.assignment_id,
                "groupId": chosen.group_id,
                "teacherId": chosen.teacher_id,
                "audienceId": chosen.audience_id,
                "disciplineId": chosen.discipline_id,
                "lessonTypeId": chosen.lesson_type_id,
                "date": chosen.lesson_date.isoformat(),
                "slotId": chosen.slot_id,
                "subgroup": chosen.subgroup,
            }
        )

    # Add existing lessons so that ScheduleSolverService re-applies them
    for lesson in existing_lessons:
        scheduled.append(
            {
                "assignmentId": 0,
                "groupId": lesson.group_id,
                "teacherId": lesson.teacher_id,
                "audienceId": lesson.audience_id,
                "disciplineId": lesson.discipline_id,
                "lessonTypeId": lesson.lesson_type_id,
                "date": lesson.lesson_date.isoformat(),
                "slotId": lesson.slot_id,
                "subgroup": lesson.subgroup,
            }
        )

    return {
        "lessons": scheduled,
        "objectiveScore": 0,
        "solverStats": {
            "status": "FEASIBLE" if scheduled else "EMPTY",
            "solveTimeSec": solver.WallTime(),
            "iterations": solver.NumConflicts(),
        },
    }


def main(argv: List[str]) -> int:
    args = parse_args(argv)
    try:
        request = load_request(args.request)
        solution = build_solution(request, verbose=args.verbose)
    except Exception as exc:  # noqa: BLE001
        sys.stderr.write(f"Solver error: {exc}\n")
        return 1

    output_text = json.dumps(solution, ensure_ascii=False, indent=2)
    if args.output:
        args.output.write_text(output_text + "\n", encoding="utf-8")
    else:
        sys.stdout.write(output_text + "\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
