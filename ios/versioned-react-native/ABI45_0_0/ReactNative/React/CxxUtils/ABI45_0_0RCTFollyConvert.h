/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#include <folly/dynamic.h>

namespace ABI45_0_0facebook {
namespace ABI45_0_0React {

folly::dynamic convertIdToFollyDynamic(id json);
id convertFollyDynamicToId(const folly::dynamic &dyn);

} // namespace ABI45_0_0React
} // namespace ABI45_0_0facebook
