class CSVHelpers {
  /// Escapes a CSV field by wrapping in quotes and escaping internal quotes
  static String escapeCsvField(String field) {
    if (field.isEmpty) return '';

    // If field contains comma, quote, newline, or carriage return, wrap in quotes
    if (field.contains(',') ||
        field.contains('"') ||
        field.contains('\n') ||
        field.contains('\r') ||
        field.startsWith(' ') ||
        field.endsWith(' ')) {
      // Escape internal quotes by doubling them
      String escaped = field.replaceAll('"', '""');
      return '"$escaped"';
    }
    return field;
  }

  /// Parses a CSV row into individual fields, handling quoted fields properly
  static List<String> parseCsvRow(String row) {
    if (row.isEmpty) return [];

    List<String> fields = [];
    bool inQuotes = false;
    String currentField = '';

    for (int i = 0; i < row.length; i++) {
      String char = row[i];

      if (char == '"') {
        if (inQuotes && i + 1 < row.length && row[i + 1] == '"') {
          // Double quote - add single quote to field
          currentField += '"';
          i++; // Skip next quote
        } else {
          // Toggle quote state
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        // End of field
        fields.add(currentField.trim());
        currentField = '';
      } else {
        // Regular character
        currentField += char;
      }
    }

    // Add the last field
    fields.add(currentField.trim());
    return fields;
  }

  /// Advanced CSV row parser that handles edge cases
  static List<String> parseAdvancedCsvRow(String row) {
    if (row.isEmpty) return [];

    List<String> fields = [];
    StringBuffer currentField = StringBuffer();
    bool inQuotes = false;
    bool hasQuotes = false;

    for (int i = 0; i < row.length; i++) {
      String char = row[i];

      switch (char) {
        case '"':
          if (!inQuotes) {
            // Starting quoted field
            inQuotes = true;
            hasQuotes = true;
          } else if (i + 1 < row.length && row[i + 1] == '"') {
            // Escaped quote - add one quote to field
            currentField.write('"');
            i++; // Skip next quote
          } else {
            // End quoted field
            inQuotes = false;
          }
          break;

        case ',':
          if (inQuotes) {
            // Comma inside quotes - part of field
            currentField.write(char);
          } else {
            // Field separator
            String fieldValue = currentField.toString();
            if (!hasQuotes) {
              fieldValue = fieldValue.trim();
            }
            fields.add(fieldValue);
            currentField.clear();
            hasQuotes = false;
          }
          break;

        default:
          currentField.write(char);
          break;
      }
    }

    // Add the last field
    String fieldValue = currentField.toString();
    if (!hasQuotes) {
      fieldValue = fieldValue.trim();
    }
    fields.add(fieldValue);

    return fields;
  }

  /// Converts a string value to the appropriate type based on type string
  static dynamic convertStringToType(String valueStr, String type) {
    if (valueStr.isEmpty) {
      switch (type.toLowerCase()) {
        case 'bool':
          return false;
        case 'int':
          return 0;
        case 'double':
          return 0.0;
        case 'datetime':
          return DateTime.now();
        default:
          return '';
      }
    }

    try {
      switch (type.toLowerCase()) {
        case 'bool':
          return valueStr.toLowerCase() == 'true' || valueStr == '1';
        case 'int':
          return int.parse(valueStr);
        case 'double':
          return double.parse(valueStr);
        case 'datetime':
          return DateTime.parse(valueStr);
        case 'date':
          return DateTime.parse(valueStr);
        case 'time':
        // Parse time in HH:mm format
          if (valueStr.contains(':')) {
            List<String> parts = valueStr.split(':');
            if (parts.length >= 2) {
              int hour = int.parse(parts[0]);
              int minute = int.parse(parts[1]);
              return DateTime(0, 1, 1, hour, minute);
            }
          }
          return DateTime.now();
        default:
          return valueStr;
      }
    } catch (e) {
      // Return default value if parsing fails
      switch (type.toLowerCase()) {
        case 'bool':
          return false;
        case 'int':
          return 0;
        case 'double':
          return 0.0;
        case 'datetime':
        case 'date':
        case 'time':
          return DateTime.now();
        default:
          return valueStr;
      }
    }
  }

  /// Converts a value to a string for CSV storage
  static String convertTypeToString(dynamic value) {
    if (value == null) return '';

    if (value is DateTime) {
      return value.toIso8601String();
    } else if (value is bool) {
      return value.toString();
    } else if (value is num) {
      return value.toString();
    } else {
      return value.toString();
    }
  }

  /// Gets the type string for a value
  static String getTypeString(dynamic value) {
    if (value == null) return 'String';

    if (value is bool) return 'bool';
    if (value is int) return 'int';
    if (value is double) return 'double';
    if (value is DateTime) return 'datetime';
    return 'String';
  }

  /// Validates CSV format by checking header structure
  static bool validateCsvFormat(String csvContent, String expectedHeader) {
    if (csvContent.isEmpty) return false;

    final lines = csvContent.split('\n');
    if (lines.isEmpty) return false;

    final header = lines[0].trim();
    return header == expectedHeader;
  }

  /// Validates CSV format with flexible header checking
  static bool validateCsvFormatFlexible(String csvContent, List<String> requiredColumns) {
    if (csvContent.isEmpty) return false;

    final lines = csvContent.split('\n');
    if (lines.isEmpty) return false;

    final headerFields = parseCsvRow(lines[0]);

    // Check if all required columns are present
    for (String column in requiredColumns) {
      if (!headerFields.contains(column)) {
        return false;
      }
    }

    return true;
  }

  /// Sanitizes a string for safe CSV storage
  static String sanitizeString(String input) {
    if (input.isEmpty) return input;

    // Remove or replace problematic characters
    String sanitized = input
        .replaceAll('\r\n', ' ') // Replace CRLF with space
        .replaceAll('\n', ' ')   // Replace LF with space
        .replaceAll('\r', ' ')   // Replace CR with space
        .replaceAll('\t', ' ')   // Replace tabs with space
        .trim();

    // Remove extra whitespace
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');

    // Remove potentially dangerous characters (fixed regex)
    sanitized = sanitized.replaceAll(RegExp(r'[^\w\s\-\.\,\(\)]'), '');

    return sanitized;
  }

  /// Advanced string sanitization with options
  static String sanitizeStringAdvanced(String input, {
    bool removeSpecialChars = false,
    bool preserveLineBreaks = false,
    int? maxLength,
  }) {
    if (input.isEmpty) return input;

    String sanitized = input;

    if (!preserveLineBreaks) {
      sanitized = sanitized
          .replaceAll('\r\n', ' ')
          .replaceAll('\n', ' ')
          .replaceAll('\r', ' ');
    }

    // Replace tabs with spaces
    sanitized = sanitized.replaceAll('\t', ' ');

    if (removeSpecialChars) {
      sanitized = sanitized.replaceAll(RegExp(r'[^\w\s\-\.]'), '');
    }

    // Remove extra whitespace
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (maxLength != null && sanitized.length > maxLength) {
      sanitized = sanitized.substring(0, maxLength);
    }

    return sanitized;
  }

  /// Creates a CSV row from a list of values
  static String createCsvRow(List<dynamic> values) {
    return values
        .map((value) => escapeCsvField(convertTypeToString(value)))
        .join(',');
  }

  /// Creates a CSV row with specific formatting
  static String createFormattedCsvRow(Map<String, dynamic> data, List<String> columnOrder) {
    List<dynamic> orderedValues = [];

    for (String column in columnOrder) {
      orderedValues.add(data[column] ?? '');
    }

    return createCsvRow(orderedValues);
  }

  /// Validates that a CSV row has the expected number of fields
  static bool validateRowFieldCount(String row, int expectedCount) {
    final fields = parseCsvRow(row);
    return fields.length >= expectedCount;
  }

  /// Validates row field count with tolerance
  static bool validateRowFieldCountTolerant(String row, int expectedCount, {int tolerance = 0}) {
    final fields = parseCsvRow(row);
    return fields.length >= (expectedCount - tolerance) &&
        fields.length <= (expectedCount + tolerance);
  }

  /// Extracts the file name from a full path
  static String getFileNameFromPath(String path) {
    final parts = path.split('/');
    return parts.isNotEmpty ? parts.last : '';
  }

  /// Extracts file extension from path
  static String getFileExtension(String path) {
    final fileName = getFileNameFromPath(path);
    final lastDot = fileName.lastIndexOf('.');
    return lastDot != -1 ? fileName.substring(lastDot + 1) : '';
  }

  /// Creates a backup filename with timestamp
  static String createBackupFileName(String baseName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = baseName.contains('.') ? '' : '.csv';
    return '${baseName}_backup_$timestamp$extension';
  }

  /// Creates a timestamped filename
  static String createTimestampedFileName(String baseName, {String? extension}) {
    final now = DateTime.now();
    final timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    final ext = extension ?? '.csv';
    return '${baseName}_$timestamp$ext';
  }

  /// Validates email format (comprehensive) - Fixed regex
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;

    const emailRegex = r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$';
    return RegExp(emailRegex).hasMatch(email);
  }

  /// Validates phone number format
  static bool isValidPhoneNumber(String phone) {
    if (phone.isEmpty) return false;

    const phoneRegex = r'^\+?[\d\s\-\(\)]{10,}$';
    return RegExp(phoneRegex).hasMatch(phone);
  }

  /// Validates that a date string is in proper format
  static bool isValidDateString(String dateStr) {
    if (dateStr.isEmpty) return false;

    try {
      DateTime.parse(dateStr);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Validates numeric string
  static bool isValidNumber(String numberStr, {bool allowDecimals = true}) {
    if (numberStr.isEmpty) return false;

    if (allowDecimals) {
      return double.tryParse(numberStr) != null;
    } else {
      return int.tryParse(numberStr) != null;
    }
  }

  /// Formats a file size in bytes to human readable format
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Counts the number of non-empty lines in CSV content
  static int countDataRows(String csvContent) {
    if (csvContent.isEmpty) return 0;

    final lines = csvContent.split('\n');
    int count = 0;

    // Skip header (first line) and count non-empty lines
    for (int i = 1; i < lines.length; i++) {
      if (lines[i].trim().isNotEmpty) {
        count++;
      }
    }

    return count;
  }

  /// Counts total lines including header
  static int countTotalRows(String csvContent) {
    if (csvContent.isEmpty) return 0;

    final lines = csvContent.split('\n');
    return lines.where((line) => line.trim().isNotEmpty).length;
  }

  /// Merges multiple CSV files with the same structure
  static String mergeCsvFiles(List<String> csvContents, String header) {
    if (csvContents.isEmpty) return header;

    StringBuffer merged = StringBuffer();
    merged.writeln(header);

    for (String csv in csvContents) {
      if (csv.isEmpty) continue;

      final lines = csv.split('\n');
      // Skip header and add data rows
      for (int i = 1; i < lines.length; i++) {
        if (lines[i].trim().isNotEmpty) {
          merged.writeln(lines[i]);
        }
      }
    }

    return merged.toString();
  }

  /// Sorts CSV data by a specific column index
  static String sortCsvByColumn(String csvContent, int columnIndex, {bool ascending = true}) {
    if (csvContent.isEmpty) return csvContent;

    final lines = csvContent.split('\n');
    if (lines.length <= 1) return csvContent;

    final header = lines[0];
    final dataRows = lines.sublist(1).where((line) => line.trim().isNotEmpty).toList();

    // Sort data rows
    dataRows.sort((a, b) {
      final fieldsA = parseCsvRow(a);
      final fieldsB = parseCsvRow(b);

      if (fieldsA.length <= columnIndex || fieldsB.length <= columnIndex) {
        return 0;
      }

      final valueA = fieldsA[columnIndex];
      final valueB = fieldsB[columnIndex];

      // Try to parse as numbers first, then as dates, then as strings
      final numA = double.tryParse(valueA);
      final numB = double.tryParse(valueB);

      int comparison;
      if (numA != null && numB != null) {
        comparison = numA.compareTo(numB);
      } else {
        // Try parsing as dates
        final dateA = DateTime.tryParse(valueA);
        final dateB = DateTime.tryParse(valueB);

        if (dateA != null && dateB != null) {
          comparison = dateA.compareTo(dateB);
        } else {
          comparison = valueA.compareTo(valueB);
        }
      }

      return ascending ? comparison : -comparison;
    });

    // Reconstruct CSV
    final result = StringBuffer();
    result.writeln(header);
    for (String row in dataRows) {
      result.writeln(row);
    }

    return result.toString();
  }

  /// Filters CSV data based on column value
  static String filterCsvByColumn(String csvContent, int columnIndex, String filterValue, {bool exactMatch = true}) {
    if (csvContent.isEmpty) return csvContent;

    final lines = csvContent.split('\n');
    if (lines.length <= 1) return csvContent;

    final header = lines[0];
    final result = StringBuffer();
    result.writeln(header);

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final fields = parseCsvRow(line);
      if (fields.length > columnIndex) {
        final value = fields[columnIndex];
        bool matches = exactMatch
            ? value == filterValue
            : value.toLowerCase().contains(filterValue.toLowerCase());

        if (matches) {
          result.writeln(line);
        }
      }
    }

    return result.toString();
  }

  /// Removes duplicate rows from CSV (based on specific columns)
  static String removeDuplicateRows(String csvContent, List<int> keyColumnIndexes) {
    if (csvContent.isEmpty) return csvContent;

    final lines = csvContent.split('\n');
    if (lines.length <= 1) return csvContent;

    final header = lines[0];
    final result = StringBuffer();
    result.writeln(header);

    Set<String> seenKeys = {};

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final fields = parseCsvRow(line);

      // Create key from specified columns
      List<String> keyParts = [];
      for (int index in keyColumnIndexes) {
        if (index < fields.length) {
          keyParts.add(fields[index]);
        }
      }
      String key = keyParts.join('|');

      if (!seenKeys.contains(key)) {
        seenKeys.add(key);
        result.writeln(line);
      }
    }

    return result.toString();
  }

  /// Validates CSV structure and returns detailed report
  static Map<String, dynamic> analyzeCsvStructure(String csvContent) {
    Map<String, dynamic> analysis = {
      'isValid': false,
      'totalRows': 0,
      'dataRows': 0,
      'columns': 0,
      'columnNames': <String>[],
      'errors': <String>[],
      'warnings': <String>[],
    };

    if (csvContent.isEmpty) {
      analysis['errors'].add('CSV content is empty');
      return analysis;
    }

    final lines = csvContent.split('\n');
    final nonEmptyLines = lines.where((line) => line.trim().isNotEmpty).toList();

    analysis['totalRows'] = nonEmptyLines.length;

    if (nonEmptyLines.isEmpty) {
      analysis['errors'].add('No valid rows found');
      return analysis;
    }

    // Analyze header
    final headerFields = parseCsvRow(nonEmptyLines[0]);
    analysis['columns'] = headerFields.length;
    analysis['columnNames'] = headerFields;
    analysis['dataRows'] = nonEmptyLines.length - 1;

    // Check for empty column names
    for (int i = 0; i < headerFields.length; i++) {
      if (headerFields[i].trim().isEmpty) {
        analysis['warnings'].add('Column ${i + 1} has empty name');
      }
    }

    // Check data rows consistency
    int expectedColumns = headerFields.length;
    for (int i = 1; i < nonEmptyLines.length; i++) {
      final rowFields = parseCsvRow(nonEmptyLines[i]);
      if (rowFields.length != expectedColumns) {
        analysis['warnings'].add('Row ${i + 1} has ${rowFields.length} columns, expected $expectedColumns');
      }
    }

    analysis['isValid'] = (analysis['errors'] as List).isEmpty;

    return analysis;
  }

  /// Exports data to CSV with custom formatting
  static String exportToCsv(List<Map<String, dynamic>> data, List<String> columns, {String? customHeader}) {
    if (data.isEmpty) return customHeader ?? columns.join(',');

    StringBuffer csv = StringBuffer();

    // Add header
    if (customHeader != null) {
      csv.writeln(customHeader);
    } else {
      csv.writeln(columns.map((col) => escapeCsvField(col)).join(','));
    }

    // Add data rows
    for (Map<String, dynamic> row in data) {
      List<String> values = [];
      for (String column in columns) {
        values.add(escapeCsvField(convertTypeToString(row[column])));
      }
      csv.writeln(values.join(','));
    }

    return csv.toString();
  }

  /// Imports CSV data to list of maps
  static List<Map<String, dynamic>> importFromCsv(String csvContent) {
    List<Map<String, dynamic>> data = [];

    if (csvContent.isEmpty) return data;

    final lines = csvContent.split('\n');
    final nonEmptyLines = lines.where((line) => line.trim().isNotEmpty).toList();

    if (nonEmptyLines.length < 2) return data; // Need at least header + 1 data row

    final headerFields = parseCsvRow(nonEmptyLines[0]);

    for (int i = 1; i < nonEmptyLines.length; i++) {
      final rowFields = parseCsvRow(nonEmptyLines[i]);
      Map<String, dynamic> row = {};

      for (int j = 0; j < headerFields.length && j < rowFields.length; j++) {
        row[headerFields[j]] = rowFields[j];
      }

      data.add(row);
    }

    return data;
  }
}