# Modern_Concurrency

https://github.com/raywenderlich/mcon-materials/tree/editions/1.0

1.
Swift 5.5 introduces a new concurrency model that solves many of the existing concurrency issues, like thread explosion, priority inversion, and loose integration with the language and the runtime.
The **async** keyword defines a function as asynchronous. await lets you wait in a non-blocking fashion for the result of the asynchronous function.
Use the **task**(priority:_:) view modifier as an onAppear(_:) alternative when you want to run asynchronous code.
You can naturally loop over an asynchronous sequence over time by using a **for try await loop** syntax.
