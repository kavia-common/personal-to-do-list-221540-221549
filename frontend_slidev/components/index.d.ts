/**
 * This file provides TypeScript hints for auto-registered components.
 * Slidev auto-imports Vue components in the `components/` directory by name.
 */
declare module 'vue' {
  export interface GlobalComponents {
    TodoList: typeof import('./TodoList.vue')['default']
  }
}
export {}
