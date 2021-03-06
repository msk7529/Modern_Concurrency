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

6.
Annotate your test method with **async** to enable testing asynchronous code.

Use **await** with asynchronous functions to verify their output or side effects after they resume.

Use either **mock types** for your dependencies or the **real type**, if you can configure it for testing.

To test time-sensitive asynchronous code, run **concurrent tasks** to both trigger the code under test and observe its output or side effects.

**await** can suspend indefinitely. So, when testing, it’s a good idea to set a **timeout** for the tested asynchronous APIs whenever possible.


7.

To run an arbitrary number of concurrent tasks, create a **task group**. Do this by using the function withTaskGroup(of:returning:body:). For a throwing task group, use withThrowingTaskGroup(of:returning:body:).

You can **add tasks** to a group by calling addTask(priority:operation:) or addTaskUnlessCancelled(priority:operation:).

Control task execution by **canceling the group** via cancelAll() or **waiting for all tasks to complete** with waitForAll().

Use the group as an **asynchronous sequence** to iterate over each task result in real time.


8.

The **actor** type is a thread-safe type that protects its internals from concurrent access, supported by compile-time checks and diagnostics.

Actors allow **“internal” synchronous access** to their state while the compiler enforces **asynchronous calls for access** from the “outside”.

Actor methods prefixed with the **nonisolated** keyword behave as standard class methods and provide no isolation mechanics.

Actors use a runtime-managed **serial executor** to serialize calls to methods and access to properties.

The **Sendable** protocol indicates a value is safe to use in a concurrent context. The **@Sendable** attribute requires a sendable value for a method or a closure parameter.

9.

**Global actors** protect the global mutable state within your app.

Use **@globalActor** to annotate an actor as global and make it conform to the GlobalActor protocol.

Use a global actor’s **serial executor** to form concurrency-safe silos out of code that needs to work with the same mutable state.

Use a mix of **actors** and **global actors**, along with **async/await** and **asynchronous sequences**, to make your concurrent code safe.

