/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "ABI45_0_0PlatformRunLoopObserver.h"

#import <mutex>

namespace ABI45_0_0facebook {
namespace ABI45_0_0React {

static CFRunLoopActivity toCFRunLoopActivity(RunLoopObserver::Activity activity)
{
  auto result = CFRunLoopActivity{};

  if (RunLoopObserver::Activity(activity & RunLoopObserver::Activity::BeforeWaiting) ==
      RunLoopObserver::Activity::BeforeWaiting) {
    result = result | kCFRunLoopBeforeWaiting;
  }

  if (RunLoopObserver::Activity(activity & RunLoopObserver::Activity::AfterWaiting) ==
      RunLoopObserver::Activity::AfterWaiting) {
    result = result | kCFRunLoopAfterWaiting;
  }

  return result;
}

static RunLoopObserver::Activity toRunLoopActivity(CFRunLoopActivity activity)
{
  auto result = RunLoopObserver::Activity{};

  if (CFRunLoopActivity(activity & kCFRunLoopBeforeWaiting) == kCFRunLoopBeforeWaiting) {
    result = RunLoopObserver::Activity(result | RunLoopObserver::Activity::BeforeWaiting);
  }

  if (CFRunLoopActivity(activity & kCFRunLoopAfterWaiting) == kCFRunLoopAfterWaiting) {
    result = RunLoopObserver::Activity(result | RunLoopObserver::Activity::AfterWaiting);
  }

  return result;
}

PlatformRunLoopObserver::PlatformRunLoopObserver(
    RunLoopObserver::Activity activities,
    RunLoopObserver::WeakOwner const &owner,
    CFRunLoopRef runLoop)
    : RunLoopObserver(activities, owner), runLoop_(runLoop)
{
  // A value (not a reference) to be captured by the block.
  auto weakOwner = owner;

  // The documentation for `CFRunLoop` family API states that all of the methods are thread-safe.
  // See "Thread Safety and Run Loop Objects" section of the "Threading Programming Guide" for more details.
  mainRunLoopObserver_ = CFRunLoopObserverCreateWithHandler(
      NULL /* allocator */,
      toCFRunLoopActivity(activities_) /* activities */,
      true /* repeats */,
      0 /* order */,
      ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
        auto strongOwner = weakOwner.lock();
        if (!strongOwner) {
          return;
        }

        this->activityDidChange(toRunLoopActivity(activity));
      });

  assert(mainRunLoopObserver_);
}

PlatformRunLoopObserver::~PlatformRunLoopObserver()
{
  stopObserving();
  CFRelease(mainRunLoopObserver_);
}

void PlatformRunLoopObserver::startObserving() const noexcept
{
  CFRunLoopAddObserver(runLoop_, mainRunLoopObserver_, kCFRunLoopCommonModes);
}

void PlatformRunLoopObserver::stopObserving() const noexcept
{
  CFRunLoopRemoveObserver(runLoop_, mainRunLoopObserver_, kCFRunLoopCommonModes);
}

bool PlatformRunLoopObserver::isOnRunLoopThread() const noexcept
{
  return CFRunLoopGetCurrent() == runLoop_;
}

} // namespace ABI45_0_0React
} // namespace ABI45_0_0facebook
