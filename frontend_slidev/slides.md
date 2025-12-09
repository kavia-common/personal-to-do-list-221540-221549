---
# Global deck settings
theme: default
title: "To-Do List — Ocean Professional"
info: |
  Interactive To-Do app inside Slidev
class: text-left
mdc: true
transition: slide-left
fonts:
  sans: Inter, ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Helvetica Neue, Arial
  mono: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace
css: |
  @import "./style.css";
---

# To-Do List

<div class="with-hero-glow">
  <p class="muted">Add, edit, complete, and delete tasks. Your tasks are saved in your browser.</p>
</div>

<TodoList />

---
layout: center
class: text-center
---

# Tips

- Press Enter to add a task
- Double-click a task to edit
- Use the filters to view all/active/completed
- Your tasks persist using localStorage
