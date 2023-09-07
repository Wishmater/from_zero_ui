import 'package:flutter/material.dart';


class NoEnsureVisibleWidgetTraversalPolicy extends WidgetOrderTraversalPolicy {

  @override
  bool next(FocusNode currentNode) => _moveFocus(currentNode, forward: true);

  @override
  bool previous(FocusNode currentNode) => _moveFocus(currentNode, forward: false);

  bool _moveFocus(FocusNode currentNode, {required bool forward}) {
    final FocusScopeNode nearestScope = currentNode.nearestScope!;
    invalidateScopeData(nearestScope);
    final FocusNode? focusedChild = nearestScope.focusedChild;
    if (focusedChild == null) {
      final FocusNode? firstFocus = forward ? findFirstFocus(currentNode) : findLastFocus(currentNode);
      if (firstFocus != null) {
        firstFocus.requestFocus();
        return true;
      }
    }
    final List<FocusNode> sortedNodes = _sortAllDescendants(nearestScope, currentNode);
    if (forward && focusedChild == sortedNodes.last) {
      sortedNodes.first.requestFocus();
      return true;
    }
    if (!forward && focusedChild == sortedNodes.first) {
      sortedNodes.last.requestFocus();
      return true;
    }

    final Iterable<FocusNode> maybeFlipped = forward ? sortedNodes : sortedNodes.reversed;
    FocusNode? previousNode;
    for (final FocusNode node in maybeFlipped) {
      if (previousNode == focusedChild) {
        node.requestFocus();
        return true;
      }
      previousNode = node;
    }
    return false;
  }

  @override
  Iterable<FocusNode> sortDescendants(Iterable<FocusNode> descendants, FocusNode currentNode) => descendants;

  // Sort all descendants, taking into account the FocusTraversalGroup
  // that they are each in, and filtering out non-traversable/focusable nodes.
  List<FocusNode> _sortAllDescendants(FocusScopeNode scope, FocusNode currentNode) {
    final _FocusTraversalGroupMarker? scopeGroupMarker = _getMarker(scope.context);
    final FocusTraversalPolicy defaultPolicy = scopeGroupMarker?.policy ?? ReadingOrderTraversalPolicy();
    // Build the sorting data structure, separating descendants into groups.
    final Map<FocusNode?, _FocusTraversalGroupInfo> groups = <FocusNode?, _FocusTraversalGroupInfo>{};
    for (final FocusNode node in scope.descendants) {
      final _FocusTraversalGroupMarker? groupMarker = _getMarker(node.context);
      final FocusNode? groupNode = groupMarker?.focusNode;
      // Group nodes need to be added to their parent's node, or to the "null"
      // node if no parent is found. This creates the hierarchy of group nodes
      // and makes it so the entire group is sorted along with the other members
      // of the parent group.
      if (node == groupNode) {
        // To find the parent of the group node, we need to skip over the parent
        // of the Focus node in _FocusTraversalGroupState.build, and start
        // looking with that node's parent, since _getMarker will return the
        // context it was called on if it matches the type.
        final BuildContext? parentContext = _getAncestor(groupNode!.context!, count: 2);
        final _FocusTraversalGroupMarker? parentMarker = _getMarker(parentContext);
        final FocusNode? parentNode = parentMarker?.focusNode;
        groups[parentNode] ??= _FocusTraversalGroupInfo(parentMarker, members: <FocusNode>[], defaultPolicy: defaultPolicy);
        assert(!groups[parentNode]!.members.contains(node));
        groups[parentNode]!.members.add(groupNode);
        continue;
      }
      // Skip non-focusable and non-traversable nodes in the same way that
      // FocusScopeNode.traversalDescendants would.
      if (node.canRequestFocus && !node.skipTraversal) {
        groups[groupNode] ??= _FocusTraversalGroupInfo(groupMarker, members: <FocusNode>[], defaultPolicy: defaultPolicy);
        assert(!groups[groupNode]!.members.contains(node));
        groups[groupNode]!.members.add(node);
      }
    }

    // // Sort the member lists using the individual policy sorts.
    // for (final FocusNode? key in groups.keys) {
    //   final List<FocusNode> sortedMembers = groups[key]!.policy.sortDescendants(groups[key]!.members, currentNode).toList();
    //   groups[key]!.members.clear();
    //   groups[key]!.members.addAll(sortedMembers);
    // }

    // Traverse the group tree, adding the children of members in the order they
    // appear in the member lists.
    final List<FocusNode> sortedDescendants = <FocusNode>[];
    void visitGroups(_FocusTraversalGroupInfo info) {
      for (final FocusNode node in info.members) {
        if (groups.containsKey(node)) {
          // This is a policy group focus node. Replace it with the members of
          // the corresponding policy group.
          visitGroups(groups[node]!);
        } else {
          sortedDescendants.add(node);
        }
      }
    }

    // Visit the children of the scope, if any.
    if (groups.isNotEmpty && groups.containsKey(scopeGroupMarker?.focusNode)) {
      visitGroups(groups[scopeGroupMarker?.focusNode]!);
    }

    // Remove the FocusTraversalGroup nodes themselves, which aren't focusable.
    // They were left in above because they were needed to find their members
    // during sorting.
    sortedDescendants.removeWhere((FocusNode node) {
      return !node.canRequestFocus || node.skipTraversal;
    });

    // Sanity check to make sure that the algorithm above doesn't diverge from
    // the one in FocusScopeNode.traversalDescendants in terms of which nodes it
    // finds.
    assert(
    sortedDescendants.length <= scope.traversalDescendants.length && sortedDescendants.toSet().difference(scope.traversalDescendants.toSet()).isEmpty,
    'Sorted descendants contains different nodes than FocusScopeNode.traversalDescendants would. '
        'These are the different nodes: ${sortedDescendants.toSet().difference(scope.traversalDescendants.toSet())}',
    );
    return sortedDescendants;
  }

  _FocusTraversalGroupMarker? _getMarker(BuildContext? context) {
    return context?.getElementForInheritedWidgetOfExactType<_FocusTraversalGroupMarker>()?.widget as _FocusTraversalGroupMarker?;
  }

  BuildContext? _getAncestor(BuildContext context, {int count = 1}) {
    BuildContext? target;
    context.visitAncestorElements((Element ancestor) {
      count--;
      if (count == 0) {
        target = ancestor;
        return false;
      }
      return true;
    });
    return target;
  }

}


class _FocusTraversalGroupInfo {
  _FocusTraversalGroupInfo(
      _FocusTraversalGroupMarker? marker, {
        FocusTraversalPolicy? defaultPolicy,
        List<FocusNode>? members,
      })  : groupNode = marker?.focusNode,
        policy = marker?.policy ?? defaultPolicy ?? ReadingOrderTraversalPolicy(),
        members = members ?? <FocusNode>[];

  final FocusNode? groupNode;
  final FocusTraversalPolicy policy;
  final List<FocusNode> members;
}


class _FocusTraversalGroupMarker extends InheritedWidget {
  const _FocusTraversalGroupMarker({
    required this.policy,
    required this.focusNode,
    required super.child,
  });

  final FocusTraversalPolicy policy;
  final FocusNode focusNode;

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => false;
}