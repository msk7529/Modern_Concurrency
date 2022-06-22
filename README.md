# Modern_Concurrency

https://github.com/raywenderlich/mcon-materials/tree/editions/1.0

1.
Swift 5.5 introduces a new concurrency model that solves many of the existing concurrency issues, like thread explosion, priority inversion, and loose integration with the language and the runtime.
The **async** keyword defines a function as asynchronous. await lets you wait in a non-blocking fashion for the result of the asynchronous function.
Use the **task**(priority:_:) view modifier as an onAppear(_:) alternative when you want to run asynchronous code.
You can naturally loop over an asynchronous sequence over time by using a **for try await loop** syntax.

2.
Functions, computed properties and closures marked with **async** run in an asynchronous context. They can suspend and resume one or more times.
**await** yields the execution to the central async handler, which decides which pending job to execute next.
An **async let** binding promises to provide a value or an error later on. You access its result using await.
**Task()** creates an asynchronous context for running on the current actor. It also lets you define the task’s priority.
Similar to DispatchQueue.main, **MainActor** is a type that executes blocks of code, functions or properties on the main thread.
