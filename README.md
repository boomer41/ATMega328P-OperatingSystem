# Simple operating system for the ATMega328P
This operating system was creating during a class assignment. The code is experimental and highly untested, but it should work.

## How it works
The OS uses a very simple round robin scheduler and does a context switch every 262144 clock cycles. This behaviour is controllable by setting OCR0A and the prescalers of Timer0. You cannot use Timer0 in your application, it is exclusively used by the scheduler.

## How to use
Simply put the files starting with `os` in your project. Edit `os_config.h` to fit your needs. From your main, call `os_init()` and create your tasks with `os_task_add(task_func, task_data)`. To start the scheduler, call `os_run()`. Note that this call never returns, so subsequent code will not be executed.

Please note that tasks currently may never terminate and **must** be terminated using `os_current_task_kill()`. To access the void-pointer given to `os_task_add`, call `os_current_task_get_data()`.

Please do not try to use recursion or deep call stacks, as you only have a very limited stack.
**You may not use Timer0, because it is used for the scheduler! Do not try to reenable interrupts when using custom interrupt service routines!**

## Configuration
The operating system can be configured at compile time using the following define-macros in `os_config.h`:
  - `OS_STACK_SIZE` controls the stack size for _one_ task.
  - `OS_TASK_COUNT` controls how many tasks _may_ be created simultaneously.

## License
Copyright 2020 Stephan Brunner

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

