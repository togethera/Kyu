# Kyu

Kyu is persistent queue system written in Swift and inspired by [Sidekiq](https://github.com/mperham/sidekiq).

I built the original version as a fire and forget way of handling the video and image uploads for [Upshot](http://upshotapp.co).

## Pretty Diagram

![](https://docs.google.com/drawings/d/1TBfSEeThljA6u3jooFRJt9u4bRWAlrRLPfxuXbec8CM/pub?w=960&h=720)

## Install

```
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '9.0'
# platform :osx, '10.11'
use_frameworks!

# Just the core, no UI
pod 'Kyu/Core', :git => 'TODO'

# Core lib + a basic UI for browsing workers and jobs
pod 'Kyu/iOS', :git => 'TODO'
```

## State

Kyu **is** being used in production however I’ve set the current version to 0.9 as I’m not 100% happy with the API and will expect it to change.

## Example

First we need to create a Job.

```
class NewLineJob: KyuJobProtocol
{
    static let filePathArgumentKey = "filePath"
    
    func perform(arguments: [String : AnyObject]) -> KyuJobResult
    {
        guard let filePath = arguments[NewLineJob.filePathArgumentKey] as? String,
              let fileHandle = NSFileHandle(forWritingAtPath: filePath) else
        {
            return KyuJobResult.fail
        }
        
        let stringToWrite = "Hello\n"
        let stringToWriteData = stringToWrite.dataUsingEncoding(NSUTF8StringEncoding)!
        
        fileHandle.seekToEndOfFile()
        fileHandle.writeData(stringToWriteData)
        fileHandle.closeFile()
        
        return KyuJobResult.success
    }
}
```

This Job will write a new line of text to a file.

Next, let’s initialize our Kyu.

```
do
{
    self.kyu = try Kyu.configure({ (config) in
        config.numberOfWorkers = 4
        config.directoryURL = kyuDirectoryURL
        config.job = NewLineJob()
        config.maximumNumberOfRetries = 5
    }
}
catch let error
{
    // …
}
```

Wonderful, now let’s add a few jobs and try it out.

```
self.kyu.queueJob([NewLineJob.filePathArgumentKey:filePath])
self.kyu.queueJob([NewLineJob.filePathArgumentKey:filePath])
self.kyu.queueJob([NewLineJob.filePathArgumentKey:filePath])
``` 

BOOM! We’ve now queued 3 jobs 🎉

## Retries

When initializing a Kyu object you can set the maximum number of retries.

Retries have an exponential backoff. This is crurently calculated with:

```
let retryTimeInterval = 30seconds * pow(numberOfRetries, 3)
```

```
do
{
    self.kyu = try Kyu.configure({ (config) in
        config.numberOfWorkers = 4
        config.directoryURL = kyuDirectoryURL
        config.job = NewLineJob()
        config.maximumNumberOfRetries = 5
    }
}
catch let error
{
    // …
}
```

This means that after the 5th retry, the job will just be deleted.

By implementing the `KyuDataSource` protocol you can have more control on whether the retry count is actually incremented.

## Cancelling Jobs

When queing a job, you are returned an identifier. You can use this identifier to cancel a job.

```
let identifier = self.kyu.queueJob([NewLineJob.filePathArgumentKey:filePath])

do
{
    try self.kyu.cancelJob(identifier)
}
catch KyuJobManagementError.JobNotFound
{

}

``` 

## Admin UI

Kyu has a simple admin interface builtin. The aim is to make to provide some transparency to help with debugging.

### iOS

To use the iOS admin UI, make sure you have the `Kyu/iOS` pod

```
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '9.0'
use_frameworks!

pod 'Kyu/iOS', :git => 'TODO'
```

All you need to do is present the `KyuWorkersListViewController` view controller.

```
self.kyu = try! Kyu.configure { (config) -> () in
    config.numberOfWorkers = 1
    config.directoryURL = directoryURL
    config.job = TestJob()
}

let kyuWorkersViewController = KyuWorkersListViewController(kyu: self.kyu)
let navigationController =  UINavigationController(rootViewController: kyuWorkersViewController)

self.presentViewController(navigationController, animated: true, completion: nil)
```

### macOS (coming soon)

## License

[MIT License](http://www.opensource.org/licenses/MIT).