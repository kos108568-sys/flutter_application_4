from ortools.sat.python import cp_model

# Данные
groups = ["ПО-32", "ПО-33", "ПО-42"]
teachers = ["Иванов", "Петров", "Сидоров"]
audiences = ["101", "202", "303"]
days = ["Пн", "Вт", "Ср", "Чт", "Пт"]
slots = [1, 2, 3, 4]   # 4 пары в день

# Модель
model = cp_model.CpModel()

# Переменные: x[g, t, a, d, s] = 1 если у группы g в день d на паре s препод t в аудитории a
x = {}
for g in groups:
    for t in teachers:
        for a in audiences:
            for d in days:
                for s in slots:
                    x[(g, t, a, d, s)] = model.NewBoolVar(f"x_{g}_{t}_{a}_{d}_{s}")

# Ограничения: у каждой группы не более одной пары на слот
for g in groups:
    for d in days:
        for s in slots:
            model.Add(sum(x[(g, t, a, d, s)] for t in teachers for a in audiences) <= 1)

# Ограничения: преподаватель не ведёт две пары одновременно
for t in teachers:
    for d in days:
        for s in slots:
            model.Add(sum(x[(g, t, a, d, s)] for g in groups for a in audiences) <= 1)

# Ограничения: аудитория не занята двумя группами
for a in audiences:
    for d in days:
        for s in slots:
            model.Add(sum(x[(g, t, a, d, s)] for g in groups for t in teachers) <= 1)

# Цель — просто найти допустимое расписание
model.Maximize(sum(x.values()))

# Решатель
solver = cp_model.CpSolver()
solver.parameters.max_time_in_seconds = 10
status = solver.Solve(model)

# Вывод результата
if status == cp_model.OPTIMAL or status == cp_model.FEASIBLE:
    for d in days:
        print(f"\n📅 {d}")
        for s in slots:
            for g in groups:
                for t in teachers:
                    for a in audiences:
                        if solver.Value(x[(g, t, a, d, s)]):
                            print(f"  Пара {s}: группа {g} — {t} в ауд. {a}")
else:
    print("❌ Нет допустимого решения.")
