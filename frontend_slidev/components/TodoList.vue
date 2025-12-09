<script setup lang="ts">
import { reactive, ref, watch, computed, onMounted, nextTick } from 'vue'

type Todo = {
  id: string
  title: string
  completed: boolean
  createdAt: number
  updatedAt: number
  editing?: boolean
}

const STORAGE_KEY = 'slidev_todos_v1'

// reactive state
const todos = reactive<Todo[]>([])

const newTitle = ref('')
const filter = ref<'all' | 'active' | 'completed'>('all')

// load from localStorage
onMounted(() => {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (raw) {
      const data = JSON.parse(raw) as Todo[]
      if (Array.isArray(data)) {
        data.forEach(t => todos.push({ ...t, editing: false }))
      }
    }
  } catch (e) {
    // no-op on parse error, start clean
    // eslint-disable-next-line no-console
    console.warn('Failed to parse localStorage todos', e)
  }
})

// persist to localStorage on change
watch(
  () => todos.map(t => ({ id: t.id, title: t.title, completed: t.completed, createdAt: t.createdAt, updatedAt: t.updatedAt })),
  (val) => {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(val))
    } catch (e) {
      // eslint-disable-next-line no-console
      console.warn('Failed to save todos', e)
    }
  },
  { deep: true }
)

function uid() {
  return Math.random().toString(36).slice(2) + Date.now().toString(36)
}

// PUBLIC_INTERFACE
function addTodo() {
  /** Adds a new todo using the input text or ignores empty/whitespace-only entries. */
  const title = newTitle.value.trim()
  if (!title) return
  const now = Date.now()
  todos.unshift({
    id: uid(),
    title,
    completed: false,
    createdAt: now,
    updatedAt: now,
    editing: false,
  })
  newTitle.value = ''
}

function toggleTodo(id: string) {
  const t = todos.find(t => t.id === id)
  if (!t) return
  t.completed = !t.completed
  t.updatedAt = Date.now()
}

function deleteTodo(id: string) {
  const idx = todos.findIndex(t => t.id === id)
  if (idx >= 0) todos.splice(idx, 1)
}

const editingInputRefs = new Map<string, HTMLInputElement | null>()

function startEdit(id: string) {
  const t = todos.find(t => t.id === id)
  if (!t) return
  t.editing = true
  nextTick(() => {
    const el = editingInputRefs.get(id)
    if (el) {
      el.focus()
      el.select()
    }
  })
}

function stopEdit(id: string, commit = true) {
  const t = todos.find(t => t.id === id)
  if (!t) return
  if (commit) {
    const input = editingInputRefs.get(id)
    const val = (input?.value ?? t.title).trim()
    if (val) {
      t.title = val
      t.updatedAt = Date.now()
    }
  }
  t.editing = false
}

const filtered = computed(() => {
  if (filter.value === 'active') return todos.filter(t => !t.completed)
  if (filter.value === 'completed') return todos.filter(t => t.completed)
  return todos
})

const remainingCount = computed(() => todos.filter(t => !t.completed).length)
const completedCount = computed(() => todos.filter(t => t.completed).length)

function clearCompleted() {
  for (let i = todos.length - 1; i >= 0; i--) {
    if (todos[i].completed) todos.splice(i, 1)
  }
}

function handleNewKey(e: KeyboardEvent) {
  if (e.key === 'Enter') addTodo()
}
</script>

<template>
  <div class="todo-wrap">
    <div class="todo-header with-gradient">
      <div>
        <h2 class="todo-title">My Tasks</h2>
        <p class="todo-subtitle">Stay on top of your day</p>
      </div>
      <div class="todo-meta">
        <span class="badge badge-info">{{ remainingCount }} active</span>
        <span class="badge badge-muted">{{ completedCount }} done</span>
      </div>
    </div>

    <div class="todo-card">
      <div class="todo-input-row">
        <input
          v-model="newTitle"
          @keydown="handleNewKey"
          type="text"
          placeholder="Add a new task and press Enter..."
          class="todo-input"
          aria-label="Add a new task"
        />
        <button class="btn-primary" @click="addTodo" aria-label="Add task">Add</button>
      </div>

      <div class="filters">
        <button
          class="chip"
          :class="{ active: filter === 'all' }"
          @click="filter = 'all'"
          aria-pressed="filter === 'all'"
        >
          All
        </button>
        <button
          class="chip"
          :class="{ active: filter === 'active' }"
          @click="filter = 'active'"
          aria-pressed="filter === 'active'"
        >
          Active
        </button>
        <button
          class="chip"
          :class="{ active: filter === 'completed' }"
          @click="filter = 'completed'"
          aria-pressed="filter === 'completed'"
        >
          Completed
        </button>

        <div class="spacer"></div>

        <button
          class="btn-secondary small danger"
          v-if="completedCount > 0"
          @click="clearCompleted"
          aria-label="Clear completed tasks"
          title="Clear completed tasks"
        >
          Clear completed
        </button>
      </div>

      <ul class="todo-list" role="list">
        <li v-if="filtered.length === 0" class="todo-empty">
          Nothing here yet — add your first task ✨
        </li>
        <li v-for="t in filtered" :key="t.id" class="todo-item" :class="{ done: t.completed }">
          <label class="checkbox">
            <input type="checkbox" :checked="t.completed" @change="toggleTodo(t.id)" :aria-label="t.completed ? 'Mark as incomplete' : 'Mark as complete'">
            <span class="checkmark"></span>
          </label>

          <div class="todo-content">
            <template v-if="t.editing">
              <input
                :ref="(el) => editingInputRefs.set(t.id, el as HTMLInputElement)"
                type="text"
                :value="t.title"
                class="todo-edit-input"
                @keydown.enter="stopEdit(t.id, true)"
                @keydown.esc="stopEdit(t.id, false)"
                @blur="stopEdit(t.id, true)"
                aria-label="Edit task title"
              />
            </template>
            <template v-else>
              <span class="todo-text" @dblclick="startEdit(t.id)">{{ t.title }}</span>
            </template>
          </div>

          <div class="item-actions">
            <button class="ghost edit" @click="startEdit(t.id)" aria-label="Edit task">Edit</button>
            <button class="ghost delete" @click="deleteTodo(t.id)" aria-label="Delete task">Delete</button>
          </div>
        </li>
      </ul>
    </div>
  </div>
</template>

<style scoped>
/* Ocean Professional palette mapped for light-on-dark deck but clean surfaces */
:root {
  --op-primary: #2563EB;
  --op-secondary: #F59E0B;
  --op-error: #EF4444;
  --op-bg: #f9fafb;
  --op-surface: #ffffff;
  --op-text: #111827;
}

/* Container */
.todo-wrap {
  display: grid;
  gap: 16px;
}

/* Header */
.todo-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: var(--theme-bg-elevated);
  border: 1px solid var(--line, var(--theme-border-subtle));
  border-radius: 16px;
  padding: 18px 20px;
  box-shadow: 0 8px 24px rgba(0,0,0,0.25);
}
.with-gradient {
  background:
    linear-gradient(90deg, rgba(37,99,235,0.08), rgba(243,244,246,0.00)),
    var(--theme-bg-elevated);
}
.todo-title {
  margin: 0;
  font-size: clamp(20px, 2.2vw, 28px);
  font-weight: 800;
  letter-spacing: -0.02em;
}
.todo-subtitle {
  margin: 2px 0 0 0;
  color: var(--theme-text-secondary);
}
.todo-meta {
  display: flex;
  gap: 8px;
  align-items: center;
}
.badge {
  display: inline-flex;
  align-items: center;
  padding: 6px 10px;
  border-radius: 999px;
  font-weight: 700;
  font-size: 12px;
  border: 1px solid var(--line, var(--theme-border-subtle));
  background: rgba(255,255,255,0.06);
  color: var(--theme-text-primary);
}
.badge-info {
  border-color: color-mix(in oklab, var(--op-primary) 40%, #000);
  background: color-mix(in oklab, var(--op-primary) 12%, #000);
}
.badge-muted {
  color: var(--theme-text-secondary);
}

/* Card */
.todo-card {
  background: var(--theme-bg-elevated);
  border: 1px solid var(--line, var(--theme-border-subtle));
  border-radius: 16px;
  padding: 16px;
  box-shadow: 0 10px 28px rgba(0,0,0,0.28);
}

/* Input row */
.todo-input-row {
  display: grid;
  grid-template-columns: 1fr auto;
  gap: 10px;
}
.todo-input {
  background: color-mix(in oklab, var(--theme-bg-elevated) 90%, #0000);
  border: 1px solid var(--line, var(--theme-border-subtle));
  border-radius: 12px;
  padding: 12px 14px;
  outline: none;
  color: var(--theme-text-primary);
  transition: border-color 160ms ease, box-shadow 160ms ease;
}
.todo-input::placeholder {
  color: var(--theme-text-secondary);
}
.todo-input:focus {
  border-color: color-mix(in oklab, var(--op-primary) 50%, var(--theme-border-subtle));
  box-shadow: 0 0 0 3px color-mix(in oklab, var(--op-primary) 25%, #0000);
}

/* Filters */
.filters {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-top: 10px;
}
.chip {
  appearance: none;
  background: var(--theme-chip-bg, rgba(255,255,255,0.06));
  color: var(--theme-chip-fg, var(--theme-text-secondary));
  border: 1px solid var(--line, var(--theme-border-subtle));
  border-radius: 9999px;
  padding: 6px 12px;
  font-weight: 700;
  font-size: 12px;
  cursor: pointer;
  transition: background 160ms ease, transform 160ms ease, border-color 160ms ease, color 160ms ease;
}
.chip:hover {
  transform: translateY(-1px);
  border-color: color-mix(in oklab, var(--op-primary) 30%, var(--theme-border-subtle));
}
.chip.active {
  background: color-mix(in oklab, var(--op-primary) 18%, #000);
  color: var(--theme-text-primary);
  border-color: color-mix(in oklab, var(--op-primary) 45%, var(--theme-border-subtle));
}
.spacer {
  flex: 1 1 auto;
}

/* List */
.todo-list {
  list-style: none;
  margin: 12px 0 0 0;
  padding: 0;
  display: grid;
  gap: 10px;
}
.todo-empty {
  color: var(--theme-text-secondary);
  text-align: center;
  padding: 16px;
  border: 1px dashed var(--line, var(--theme-border-subtle));
  border-radius: 12px;
}

/* Item */
.todo-item {
  display: grid;
  grid-template-columns: auto 1fr auto;
  align-items: center;
  gap: 12px;
  background: color-mix(in oklab, var(--theme-bg-elevated) 88%, #0000);
  border: 1px solid var(--line, var(--theme-border-subtle));
  border-radius: 14px;
  padding: 10px 12px;
  transition: transform 160ms ease, border-color 160ms ease, box-shadow 160ms ease;
}
.todo-item:hover {
  transform: translateY(-1px);
  border-color: color-mix(in oklab, var(--op-primary) 26%, var(--theme-border-subtle));
  box-shadow: 0 10px 26px rgba(0,0,0,0.22);
}
.todo-item.done .todo-text {
  text-decoration: line-through;
  color: var(--theme-text-secondary);
}

/* Checkbox */
.checkbox {
  position: relative;
  width: 22px;
  height: 22px;
  display: grid;
  place-items: center;
}
.checkbox input {
  appearance: none;
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  border-radius: 6px;
  border: 1.5px solid var(--line, var(--theme-border-subtle));
  background: rgba(255,255,255,0.04);
  cursor: pointer;
  transition: background 160ms ease, border-color 160ms ease, box-shadow 160ms ease;
}
.checkbox input:hover {
  border-color: color-mix(in oklab, var(--op-primary) 40%, var(--theme-border-subtle));
}
.checkbox input:checked {
  background: var(--op-primary);
  border-color: var(--op-primary);
  box-shadow: 0 0 0 3px color-mix(in oklab, var(--op-primary) 30%, #0000);
}
.checkmark {
  pointer-events: none;
}

/* Content */
.todo-content {
  min-width: 0;
}
.todo-text {
  display: block;
  color: var(--theme-text-primary);
  user-select: none;
  line-height: 1.4;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.todo-edit-input {
  width: 100%;
  background: rgba(255,255,255,0.06);
  border: 1px solid var(--line, var(--theme-border-subtle));
  border-radius: 8px;
  padding: 8px 10px;
  color: var(--theme-text-primary);
  outline: none;
  transition: border-color 160ms ease, box-shadow 160ms ease;
}
.todo-edit-input:focus {
  border-color: color-mix(in oklab, var(--op-secondary) 45%, var(--theme-border-subtle));
  box-shadow: 0 0 0 3px color-mix(in oklab, var(--op-secondary) 22%, #0000);
}

/* Actions */
.item-actions {
  display: flex;
  gap: 6px;
}
.ghost {
  appearance: none;
  background: transparent;
  color: var(--theme-text-secondary);
  border: 1px solid var(--line, var(--theme-border-subtle));
  border-radius: 10px;
  padding: 6px 10px;
  font-weight: 700;
  font-size: 12px;
  cursor: pointer;
  transition: background 160ms ease, color 160ms ease, transform 160ms ease, border-color 160ms ease;
}
.ghost:hover {
  transform: translateY(-1px);
  color: var(--theme-text-primary);
  border-color: color-mix(in oklab, var(--op-primary) 30%, var(--theme-border-subtle));
}
.ghost.edit:hover {
  background: color-mix(in oklab, var(--op-secondary) 12%, #000);
}
.ghost.delete:hover {
  background: color-mix(in oklab, var(--op-error) 12%, #000);
}

/* Buttons */
.btn-primary {
  background: var(--op-primary);
  color: white;
  border-radius: 12px;
  padding: 10px 16px;
  font-weight: 800;
  border: none;
  cursor: pointer;
  box-shadow: 0 8px 24px rgba(37,99,235,0.25);
  transition: transform 160ms ease, background 160ms ease;
}
.btn-primary:hover {
  transform: translateY(-1px);
  background: #1e4ed8;
}
.btn-secondary {
  background: rgba(255,255,255,0.06);
  color: var(--theme-text-secondary);
  border: 1px solid var(--line, var(--theme-border-subtle));
  border-radius: 12px;
  padding: 8px 12px;
  font-weight: 700;
  cursor: pointer;
  transition: transform 160ms ease, background 160ms ease;
}
.btn-secondary.small {
  padding: 6px 10px;
  font-size: 12px;
}
.btn-secondary.danger:hover {
  background: color-mix(in oklab, var(--op-error) 10%, #000);
}

/* Responsive */
@media (max-width: 740px) {
  .todo-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 8px;
  }
  .todo-input-row {
    grid-template-columns: 1fr;
  }
  .item-actions {
    gap: 4px;
  }
}
</style>
