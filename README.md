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

3.
**AsyncSequence** is a protocol which resembles Sequence and allows you to iterate over a sequence of values asynchronously.

You iterate over a sequence asynchronously by using the for await ... in syntax, or directly creating an **AsyncIterator** and awaiting its next() method in the context of a while loop.

Task offers several APIs to check if the current task was canceled. If you want to throw an error upon cancellation, use **Task.checkCancellation()**. To safely check and implement custom cancellation logic, use **Task.isCancelled**.

To bind a value to a task and all its children, use the **@TaskLocal** property wrapper along with **withValue()**.

4.
You can use **iterators** and **loops** to implement your own processing logic when consuming an AsyncSequence.

**AsyncSequence** and its partner in crime, **AsyncIteratorProtocol**, let you easily create your own asynchronous sequences.

**AsyncStream** is the easiest way to create asynchronous sequences from a single Swift closure.

When working with a continuation: Use **yield(_:)** to produce a value, **yield(with:)** to both produce a value and finish the sequence or **finish()** to indicate the sequence completed.

5.
You bridge **older asynchronous design patterns to async/await** by using **CheckedContinuation** or its unsafe counterpart, UnsafeCheckedContinuation.

For each of your code paths, you need to call one of the continuation’s resume(...) methods **exactly once** to either return a value or throw an error.

You get a continuation by calling either **withCheckedContinuation(_:)** or **withCheckedThrowingContinuation(_:)**.
