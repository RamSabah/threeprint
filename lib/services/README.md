# Filament Service Documentation

## Overview
The `FilamentService` provides a complete interface for managing filament data in Firestore, including CRUD operations with proper user authentication and data validation.

## Features
- ✅ Save filament with UUID and user ID
- ✅ Real-time data synchronization
- ✅ User-specific data isolation
- ✅ Type and color filtering
- ✅ Search functionality
- ✅ Complete CRUD operations

## Usage

### Saving a Filament
```dart
final filamentService = FilamentService();

try {
  final filamentId = await filamentService.saveFilament(
    type: 'PLA',
    color: 'Red',
    count: 5,
  );
  print('Filament saved with ID: $filamentId');
} catch (e) {
  print('Error: $e');
}
```

### Getting User Filaments
```dart
// Get all filaments for current user
final filaments = await filamentService.getUserFilaments();

// Get filaments stream for real-time updates
filamentService.getUserFilamentsStream().listen((filaments) {
  // Handle filament updates
});
```

### Filtering and Search
```dart
// Get filaments by type
final plaFilaments = await filamentService.getFilamentsByType('PLA');

// Get filaments by color
final redFilaments = await filamentService.getFilamentsByColor('Red');

// Search filaments
final searchResults = await filamentService.searchFilaments('red pla');
```

## Data Structure

Each filament document contains:
- `id`: Unique UUID identifier
- `userId`: Firebase Auth user ID
- `type`: Filament type (PLA, PETG, Other)
- `color`: Color name or hex code
- `count`: Number of filament units
- `createdAt`: Document creation timestamp
- `updatedAt`: Last modification timestamp

## Security

- All operations require user authentication
- Data is automatically filtered by user ID
- Each user can only access their own filaments
- Proper error handling for authentication failures

## Error Handling

The service throws descriptive exceptions for:
- Authentication failures
- Validation errors
- Network issues
- Permission denials
- Document not found errors

Always wrap service calls in try-catch blocks for proper error handling.