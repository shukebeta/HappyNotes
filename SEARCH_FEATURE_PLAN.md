# Plan for Implementing Full-Text Search in HappyNotes Frontend

This document outlines the plan to integrate the backend's full-text search API into the HappyNotes Flutter application by enhancing the existing title-tap dialog.

## 1. Create New Utility Dialog Function

*   **File:** `lib/utils/util.dart`
*   **Action:** Create a new function `Future<Map<String, String>?> showKeywordOrTagDialog(BuildContext context, String title, String hintText)`.
*   **Details:**
    *   Base this function on the existing `showInputDialog`.
    *   Modify the `AlertDialog` to include three `TextButton` actions:
        *   "Search": Returns `{'action': 'search', 'text': controller.text}`
        *   "Go": Returns `{'action': 'go', 'text': controller.text}` (Replaces the old "OK")
        *   "Cancel": Returns `null` (or `{'action': 'cancel', 'text': ''}`)
    *   Update the dialog's title (e.g., "Find Notes") and hint text (e.g., "Enter keyword, tag, date, or ID").

## 2. Update Navigation Helper

*   **File:** `lib/utils/navigation_helper.dart`
*   **Function:** `showTagInputDialog`
*   **Action:**
    *   Replace the call to `Util.showInputDialog` with a call to the new `Util.showKeywordOrTagDialog`.
    *   Update the logic to handle the returned `Map`:
        *   If `result['action'] == 'search'`:
            *   Get `result['text']`.
            *   Call the search API (see step 5).
            *   Navigate to `SearchResultsPage` (see step 3), passing the search text.
        *   If `result['action'] == 'go'`:
            *   Use the existing logic to process `result['text']` as a tag, date, or ID and navigate to `TagNotes`, `MemoriesOnDay`, or `NoteDetail` respectively.
        *   If `result == null` or `action` is 'cancel': Do nothing.

## 3. Create Search Results Page

*   **File:** `lib/screens/search/search_results_page.dart`
*   **Action:** Create a new `StatefulWidget` named `SearchResultsPage`.
*   **Details:**
    *   Accept the search query (`String`) as a constructor parameter.
    *   Use a `SearchResultsController` (see step 4) to fetch and manage search results.
    *   Display an `AppBar` showing the search query.
    *   Display a loading indicator while fetching.
    *   Display the results using the existing `NoteList` component.
    *   Handle cases for "no results found".

## 4. Create Search Results Controller

*   **File:** `lib/screens/search/search_results_controller.dart`
*   **Action:** Create a new controller class `SearchResultsController`.
*   **Details:**
    *   Inject the `NotesService` (or relevant service).
    *   Implement a method `fetchSearchResults(String query)` that:
        *   Sets a loading state.
        *   Calls the search method in the service.
        *   Updates a list of `Note` objects with the results.
        *   Manages error states.
    *   Provide getters for the loading state and the results list.

## 5. API and Service Integration

*   **File:** `lib/apis/notes_api.dart` (or create `lib/apis/search_api.dart`)
*   **Action:** Add a method to call the backend's full-text search endpoint (e.g., `Future<List<dynamic>> searchNotes(String query)`).
*   **File:** `lib/services/notes_services.dart` (or create `lib/services/search_service.dart`)
*   **Action:** Add a corresponding service method that calls the API method and handles response parsing/error handling, returning a `List<Note>`.

## 6. Dependency Injection

*   **File:** `lib/dependency_injection.dart`
*   **Action:** Register the new `SearchResultsController` and any new services created (e.g., `SearchService`).

## Visual Flow

```mermaid
graph LR
    A[HomePage] -- Tap Title --> B{Show New KeywordOrTag Dialog};
    B -- Enter Text & Tap 'Search' --> C{NavigationHelper};
    C -- Call API --> D[Backend Search API];
    D -- Return Results --> C;
    C -- Navigate --> E[SearchResultsPage];
    E -- Display Results --> F(NoteList);

    B -- Enter Text & Tap 'Go' --> G{NavigationHelper};
    G -- Process Tag/Date/ID --> H[TagNotes / NoteDetail / MemoriesOnDay];

    B -- Tap 'Cancel' --> I(Close Dialog);