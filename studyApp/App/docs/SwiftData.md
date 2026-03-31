# SwiftData

## Models

First we need a mode;/data structure that we hold our data in. We can declare it with final class/struct; add initialisation, properties, etc. Must import SwiftData and add the @Model attribute.

# Accessing Data
Them, at the appropriate level (often the app root), attatch         .modelContainer(for: [struct.self]). This will create a container for our data, and we can then use @Environment(\.modelContext) to access the context in which we ca


- In the file you want to use the data, add @Environment(\.modelContext) var modelContext, which we'll use to insert, delete, and update data. To read data, we can use @Query to fetch data from the model container. For example, @Query var items: [Item] will fetch all items of type Item from the model container.

#Grouping / Relationships
todo





- 
