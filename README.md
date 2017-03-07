# GroceryCloud

This sample grocery app uses iCloud document storage to sync across all of a user's devices without requiring a backend server. The user's list of groceries is also preserved when the application is deleted and restored when they re-install. It is written in Swift 3, on Xcode 8.2.1.

There are a lot of reasons not to rely on iCloud for your app. If you ever plan to expand your app to the web or Android or add any manner for your users to interact with each other, this probably is not the correct route to go down.

However, retaining some information across all of a user's devices even if the app is deleted and re-installed can be exceptionally convenient.
