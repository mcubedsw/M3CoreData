M3CoreData
==========

M3CoreData adds a series of extensions to the CoreData framework. It consists of 4 items:

- **M3CoreDataManager** Hides away all the usual CoreData setup code into a separate class
- **M3JSONAtomicStore** Adds support for JSON based data stores
- **M3FixtureController** Adds support quickly generating fixture objects for testing from a JSON store
- **NSManagedObjectContext+M3Extensions** Adds some methods to simplify adding/retrieving objects

M3CoreData is licensed under the MIT licence

**Please consider this a 1.0 alpha of the framework.** While the method signatures are unlikely to change, I am not yet ready to mark this as final, so source compatibility isn't guaranteed between source checkins (ie methods may be added/removed/changed without any sort of deprecation warning). I will hopefully have a version I'm ready to declare 1.0 final in the near future.


JSON Store Format
------------------------

The JSON Store and Fixtures Controller requires a specific structure on disk. Stores are folders, which contain the following:

- A **_Metadata.json** file for storing store metadata
- A JSON file for each entity called ‹‹entity name››.json

Each entity JSON file has a root dictionary. This dictionary contains the ID (an integer) as the key and the object data (another dictionary) as the value. The object data contains the key-value pairs for the stored object. To many relationships should be represented as an array of IDs. Dates should be strings in the format yyyy-mm-dd hh:mm:ss ±hhmm.

Relationships are defined with simple IDs, in the format "‹‹entity name››.‹‹object id››".

While this store can potentially be used in production code, I would urge caution as it hasn't been extensively tested. It's primary aim is to seed test data into a Core Data store.