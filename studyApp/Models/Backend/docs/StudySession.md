
# StudySession (final class)

- When working with it, we can treat it similar to a pointer in cpp, where we can validate it's existnece using guard, and then create a copy to that element which we know is safe that points to the original object.

```swift
        guard let session = activeSession else { return }
```

