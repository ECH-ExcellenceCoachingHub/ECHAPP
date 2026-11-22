# Fix Flutter Web path_provider MissingPluginException

## Steps
- [x] 1. Analyze the root cause (path_provider not supported on web)
- [x] 2. Fix `frontend/lib/services/download_service.dart` - make web-safe
- [x] 3. Fix `frontend/lib/widgets/voice_chat_widget.dart` - guard recording on web
- [x] 4. Fix `frontend/lib/presentation/widgets/downloaded_material_viewer.dart` - guard dart:io on web
- [x] 5. Verify web-safe logic in payment_api_service.dart & certificate_service.dart
- [x] 6. Fix PDF viewers to route through media proxy on web (professional_lesson_screen, document_viewer, book_reader_screen)
- [x] 7. Fix downloaded_material_viewer.dart to open PDFs via network URL on web
- [x] 8. Test the fix (flutter build web / analyze)
