#ifndef _OS_H_
#define _OS_H_

typedef void (*os_task_func)(void*);

void os_init(void);
void os_run(void);
void os_task_add(os_task_func func, void* data);
void os_current_task_kill(void);
void* os_current_task_get_data(void);

#endif /* _OS_H_ */