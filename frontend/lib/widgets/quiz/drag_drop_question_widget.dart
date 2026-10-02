import 'package:flutter/material.dart';
import 'package:excellencecoachinghub/models/question.dart';
import 'package:excellencecoachinghub/utils/media_proxy.dart';

class DragDropQuestionWidget extends StatefulWidget {
  final Question question;
  final Function(List<Map<String, String>>) onAnswerChanged;
  final List<Map<String, String>>? currentAnswer;
  final bool isReadOnly;

  const DragDropQuestionWidget({
    super.key,
    required this.question,
    required this.onAnswerChanged,
    this.currentAnswer,
    this.isReadOnly = false,
  });

  @override
  State<DragDropQuestionWidget> createState() => _DragDropQuestionWidgetState();
}

class _DragDropQuestionWidgetState extends State<DragDropQuestionWidget> {
  List<String> availableItems = [];
  Map<String, String> placedItems = {}; // itemId -> zoneId
  Map<String, List<String>> zoneItems = {}; // zoneId -> [itemIds]
  String? selectedItem; // Currently selected item for click-to-place

  @override
  void initState() {
    super.initState();
    _initializeQuestion();
  }

  void _initializeQuestion() {
    // Extract draggable items
    availableItems = widget.question.dragDropItems?.map((item) => item.id).toList() ?? [];
    
    // Initialize zones
    if (widget.question.dropZones != null) {
      for (final zone in widget.question.dropZones!) {
        zoneItems[zone.id] = [];
      }
    }

    // Load current answer if available
    if (widget.currentAnswer != null) {
      for (final placement in widget.currentAnswer!) {
        final itemId = placement['itemId'];
        final zoneId = placement['zoneId'];
        if (itemId != null && zoneId != null) _placeItem(itemId, zoneId);
      }
    }
  }

  void _placeItem(String itemId, String zoneId) {
    setState(() {
      // Remove from available items
      availableItems.remove(itemId);
      
      // Remove from previous zone if it was placed elsewhere
      if (placedItems.containsKey(itemId)) {
        final oldZoneId = placedItems[itemId]!;
        zoneItems[oldZoneId]?.remove(itemId);
      }
      
      // Add to new zone
      placedItems[itemId] = zoneId;
      zoneItems[zoneId]?.add(itemId);
      
      // Notify parent
      _notifyAnswerChanged();
    });
  }

  void _selectItem(String itemId) {
    setState(() {
      if (selectedItem == itemId) {
        selectedItem = null; // Deselect if already selected
      } else {
        selectedItem = itemId; // Select new item
      }
    });
  }

  void _removeItem(String itemId) {
    setState(() {
      // Remove from current zone
      final zoneId = placedItems[itemId];
      if (zoneId != null) {
        zoneItems[zoneId]?.remove(itemId);
        placedItems.remove(itemId);
        
        // Add back to available items
        availableItems.add(itemId);
        
        // Clear selection if this item was selected
        if (selectedItem == itemId) {
          selectedItem = null;
        }
        
        // Notify parent
        _notifyAnswerChanged();
      }
    });
  }

  void _notifyAnswerChanged() {
    final answer = placedItems.entries.map((entry) => {
      'itemId': entry.key,
      'zoneId': entry.value,
    }).toList();
    widget.onAnswerChanged(answer);
  }

  Widget _buildDraggableItem(String itemId) {
    final item = widget.question.dragDropItems?.firstWhere((i) => i.id == itemId);
    if (item == null) return const SizedBox.shrink();

    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 600;
    final isVerySmallScreen = screenHeight < 400;

    return Draggable<String>(
      data: itemId,
      feedback: Container(
        padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
        decoration: BoxDecoration(
          color: Colors.blue[100],
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.blue),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.image != null && item.image!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Image.network(
                  mediaProxyUrl(item.image),
                  width: isSmallScreen ? 16 : 20,
                  height: isSmallScreen ? 16 : 20,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => 
                    Icon(Icons.image_not_supported, size: isSmallScreen ? 16 : 20),
                ),
              ),
            if (item.image != null && item.image!.isNotEmpty) SizedBox(width: isSmallScreen ? 4 : 8),
            Flexible(
              child: Text(
                item.content,
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14, 
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      childWhenDragging: Container(
        padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey),
        ),
        child: Text(
          item.content,
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      child: GestureDetector(
        onTap: () => _selectItem(itemId),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 2 : 4, vertical: 1),
          padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
          decoration: BoxDecoration(
            color: selectedItem == itemId ? Colors.blue[100] : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selectedItem == itemId ? Colors.blue : Colors.grey[300]!,
              width: selectedItem == itemId ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 1,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.image != null && item.image!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Image.network(
                    mediaProxyUrl(item.image),
                    width: isSmallScreen ? 16 : 20,
                    height: isSmallScreen ? 16 : 20,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => 
                      Icon(Icons.image_not_supported, size: isSmallScreen ? 16 : 20),
                  ),
                ),
              if (item.image != null && item.image!.isNotEmpty) SizedBox(width: isSmallScreen ? 4 : 6),
              Flexible(
                child: Text(
                  item.content,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 13, 
                    fontWeight: FontWeight.w500,
                    color: selectedItem == itemId ? Colors.blue[700] : null,
                  ),
                  maxLines: isVerySmallScreen ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!isSmallScreen) ...[
                const SizedBox(width: 4),
                Icon(
                  selectedItem == itemId ? Icons.check_circle : Icons.drag_handle, 
                  size: 14, 
                  color: selectedItem == itemId ? Colors.blue : Colors.grey[600]
                ),
              ] else if (selectedItem == itemId) ...[
                const SizedBox(width: 4),
                Icon(Icons.check_circle, size: 12, color: Colors.blue),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropZone(String zoneId) {
    final zone = widget.question.dropZones?.firstWhere((z) => z.id == zoneId);
    if (zone == null) return const SizedBox.shrink();

    final itemsInZone = zoneItems[zoneId] ?? [];
    final hasItems = itemsInZone.isNotEmpty;

    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 600;

    return DragTarget<String>(
      onWillAcceptWithDetails: (data) => !placedItems.containsKey(data),
      onAcceptWithDetails: (details) => _placeItem(details.data, zoneId),
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          onTap: () {
            // Handle click-to-place if an item is selected
            if (selectedItem != null && !placedItems.containsKey(selectedItem)) {
              _placeItem(selectedItem!, zoneId);
            }
          },
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(vertical: isSmallScreen ? 4 : 6),
            padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
            decoration: BoxDecoration(
              color: selectedItem != null && !placedItems.containsKey(selectedItem)
                ? Colors.orange[50]
                : candidateData.isNotEmpty 
                  ? Colors.blue[50] 
                  : hasItems 
                    ? Colors.green[50] 
                    : Colors.grey[50],
              borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
              border: Border.all(
                color: selectedItem != null && !placedItems.containsKey(selectedItem)
                  ? Colors.orange
                  : candidateData.isNotEmpty 
                    ? Colors.blue 
                    : hasItems 
                      ? Colors.green 
                      : Colors.grey[300]!,
                width: (selectedItem != null && !placedItems.containsKey(selectedItem)) || candidateData.isNotEmpty ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  zone.label,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: selectedItem != null && !placedItems.containsKey(selectedItem)
                      ? Colors.orange
                      : candidateData.isNotEmpty 
                        ? Colors.blue 
                        : hasItems 
                          ? Colors.green 
                          : Colors.grey[700],
                  ),
                ),
                SizedBox(height: isSmallScreen ? 6 : 8),
                if (hasItems)
                  Wrap(
                    spacing: 4,
                    runSpacing: 3,
                    children: itemsInZone.map((itemId) {
                      final item = widget.question.dragDropItems?.firstWhere((i) => i.id == itemId);
                      if (item == null) return const SizedBox.shrink();

                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 6 : 8, 
                          vertical: isSmallScreen ? 2 : 4
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (item.image != null && item.image!.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: Image.network(
                                  mediaProxyUrl(item.image),
                                  width: isSmallScreen ? 12 : 16,
                                  height: isSmallScreen ? 12 : 16,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => 
                                    Icon(Icons.image_not_supported, size: isSmallScreen ? 12 : 16),
                                ),
                              ),
                            if (item.image != null && item.image!.isNotEmpty) SizedBox(width: isSmallScreen ? 2 : 4),
                            Flexible(
                              child: Text(
                                item.content,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 10 : 12, 
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: isSmallScreen ? 2 : 4),
                            GestureDetector(
                              onTap: () => _removeItem(itemId),
                              child: Icon(
                                Icons.close,
                                size: isSmallScreen ? 12 : 16,
                                color: Colors.red[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  )
                else
                  Container(
                    width: double.infinity,
                    height: isSmallScreen ? 40 : 50,
                    decoration: BoxDecoration(
                      color: selectedItem != null && !placedItems.containsKey(selectedItem)
                        ? Colors.orange[100]
                        : Colors.grey[100],
                      borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8),
                      border: Border.all(
                        color: selectedItem != null && !placedItems.containsKey(selectedItem)
                          ? Colors.orange
                          : Colors.grey[300]!, 
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        selectedItem != null && !placedItems.containsKey(selectedItem)
                          ? 'Click to place here'
                          : 'Drag items here',
                        style: TextStyle(
                          color: selectedItem != null && !placedItems.containsKey(selectedItem)
                            ? Colors.orange[700]
                            : Colors.grey[600],
                          fontSize: isSmallScreen ? 12 : 14,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 600;
    final isMobile = screenWidth < 768;
    final isVerySmallScreen = screenWidth < 400;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Question text with media support
          if (widget.question.questionImage != null && widget.question.questionImage!.isNotEmpty)
            Container(
              width: double.infinity,
              height: isSmallScreen ? 120 : 200,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  mediaProxyUrl(widget.question.questionImage),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),

          Text(
            widget.question.question,
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18, 
              fontWeight: FontWeight.w600,
            ),
          ),

          SizedBox(height: isSmallScreen ? 16 : 24),

          // Two-column layout for desktop/tablet, single column for mobile
          if (isMobile)
            // Mobile layout: Drop zones first, then available items
            Column(
              children: [
                // Drop zones
                if (widget.question.dropZones != null) ...[
                  Text(
                    'Drop Zones:',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16, 
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // A drag-drop question can be saved without zones; don't crash.
                  ...?widget.question.dropZones
                      ?.map((zone) => _buildDropZone(zone.id)),
                  SizedBox(height: isSmallScreen ? 16 : 24),
                ],

                // Available items
                if (availableItems.isNotEmpty) ...[
                  Text(
                    'Available Items:',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16, 
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: availableItems
                          .map((itemId) => _buildDraggableItem(itemId))
                          .toList(),
                    ),
                  ),
                ],
              ],
            )
          else
            // Desktop/tablet layout: Two columns
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column: Available items
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Items:',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16, 
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: availableItems
                              .map((itemId) => _buildDraggableItem(itemId))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(width: isVerySmallScreen ? 8 : 16),
                
                // Right column: Drop zones
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Drop Zones:',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16, 
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (widget.question.dropZones != null)
                        ...widget.question.dropZones!
                            .map((zone) => _buildDropZone(zone.id))
                            ,
                    ],
                  ),
                ),
              ],
            ),

          SizedBox(height: isSmallScreen ? 12 : 16),

          // Instructions
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: isSmallScreen ? 18 : 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isMobile 
                        ? 'Tap to select an item, then tap a zone to place it. Or drag items. Tap X to remove.'
                        : 'Click to select an item, then click a zone to place it. Or drag items. Click X to remove.',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 11 : 13,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
