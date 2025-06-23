class DateHelpers {
  // Date format constants
  static const String defaultDateFormat = 'MM/dd/yyyy';
  static const String displayDateFormat = 'MMM dd, yyyy';
  static const String shortDateFormat = 'M/d/yy';
  static const String longDateFormat = 'EEEE, MMMM dd, yyyy';
  static const String timeFormat = 'HH:mm';
  static const String timeFormatAmPm = 'h:mm a';
  static const String dateTimeFormat = 'MMM dd, yyyy HH:mm';
  static const String isoDateFormat = 'yyyy-MM-dd';
  static const String exportDateFormat = 'yyyy-MM-dd_HH-mm-ss';

  /// Formats a date to a readable string (MM/dd/yyyy)
  static String formatDate(DateTime date, {String? format}) {
    try {
      // Simple formatting without intl for now
      if (format == null || format == defaultDateFormat) {
        return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
      }
      // Add more format cases as needed
      return '${date.month}/${date.day}/${date.year}';
    } catch (e) {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  /// Formats a date to a readable string with month name (Jan 15, 2024)
  static String formatDateWithMonthName(DateTime date) {
    try {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }

  /// Formats time to readable string
  static String formatTime(DateTime time, {bool use24Hour = true}) {
    try {
      if (use24Hour) {
        return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      } else {
        int hour = time.hour;
        String amPm = hour >= 12 ? 'PM' : 'AM';
        if (hour == 0) hour = 12;
        if (hour > 12) hour -= 12;
        return '$hour:${time.minute.toString().padLeft(2, '0')} $amPm';
      }
    } catch (e) {
      if (use24Hour) {
        return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      } else {
        int hour = time.hour;
        String amPm = hour >= 12 ? 'PM' : 'AM';
        if (hour == 0) hour = 12;
        if (hour > 12) hour -= 12;
        return '$hour:${time.minute.toString().padLeft(2, '0')} $amPm';
      }
    }
  }

  /// Formats date and time together
  static String formatDateTime(DateTime dateTime, {String? format}) {
    try {
      return '${formatDate(dateTime)} ${formatTime(dateTime)}';
    } catch (e) {
      return '${formatDate(dateTime)} ${formatTime(dateTime)}';
    }
  }

  /// Formats date for file exports
  static String formatDateForExport(DateTime date) {
    try {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}_${date.hour.toString().padLeft(2, '0')}-${date.minute.toString().padLeft(2, '0')}-${date.second.toString().padLeft(2, '0')}';
    } catch (e) {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}_${date.hour.toString().padLeft(2, '0')}-${date.minute.toString().padLeft(2, '0')}-${date.second.toString().padLeft(2, '0')}';
    }
  }

  /// Parses a date string in various formats
  static DateTime? parseDate(String dateStr) {
    if (dateStr.isEmpty) return null;

    try {
      // Try ISO format first
      if (dateStr.contains('T')) {
        return DateTime.parse(dateStr);
      }

      // Try MM/dd/yyyy format
      if (RegExp(r'^\d{1,2}/\d{1,2}/\d{4}$').hasMatch(dateStr)) {
        List<String> parts = dateStr.split('/');
        return DateTime(int.parse(parts[2]), int.parse(parts[0]), int.parse(parts[1]));
      }

      // Try yyyy-MM-dd format
      if (RegExp(r'^\d{4}-\d{1,2}-\d{1,2}$').hasMatch(dateStr)) {
        return DateTime.parse(dateStr);
      }

      // Last resort - try default parsing
      return DateTime.parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  /// Gets the number of weeks between surgery date and target date
  static int getWeeksFromSurgery(DateTime surgeryDate, DateTime targetDate) {
    final difference = targetDate.difference(surgeryDate);
    return (difference.inDays / 7).floor();
  }

  /// Gets the number of weeks since surgery to today
  static int getWeeksPostOp(DateTime surgeryDate) {
    return getWeeksFromSurgery(surgeryDate, DateTime.now());
  }

  /// Gets the number of days between two dates
  static int getDaysBetween(DateTime start, DateTime end) {
    return end.difference(start).inDays;
  }

  /// Gets the number of months between two dates (approximate)
  static int getMonthsBetween(DateTime start, DateTime end) {
    return ((end.year - start.year) * 12) + (end.month - start.month);
  }

  /// Checks if two dates are the same day (ignoring time)
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Checks if a date is today
  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  /// Checks if a date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(Duration(days: 1));
    return isSameDay(date, yesterday);
  }

  /// Checks if a date is tomorrow
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(Duration(days: 1));
    return isSameDay(date, tomorrow);
  }

  /// Checks if a date is this week
  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(Duration(days: 6));

    return date.isAfter(startOfDay(startOfWeek).subtract(Duration(seconds: 1))) &&
        date.isBefore(endOfDay(endOfWeek).add(Duration(seconds: 1)));
  }

  /// Checks if a date is this month
  static bool isThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  /// Checks if a date is this year
  static bool isThisYear(DateTime date) {
    return date.year == DateTime.now().year;
  }

  /// Gets the start of the day (00:00:00)
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Gets the end of the day (23:59:59.999)
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  /// Gets the start of the week (Monday)
  static DateTime startOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  /// Gets the end of the week (Sunday)
  static DateTime endOfWeek(DateTime date) {
    return startOfWeek(date).add(Duration(days: 6));
  }

  /// Gets the first day of the month
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Gets the last day of the month
  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59, 999);
  }

  /// Gets the number of days in a month
  static int daysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  /// Checks if a year is a leap year
  static bool isLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
  }

  /// Gets a list of dates for the current month
  static List<DateTime> getDatesInMonth(DateTime date) {
    final firstDay = startOfMonth(date);
    final lastDay = daysInMonth(date);
    final dates = <DateTime>[];

    for (int day = 1; day <= lastDay; day++) {
      dates.add(DateTime(date.year, date.month, day));
    }

    return dates;
  }

  /// Gets a list of dates for a specific week
  static List<DateTime> getWeekDates(DateTime date) {
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    final dates = <DateTime>[];

    for (int i = 0; i < 7; i++) {
      dates.add(startOfWeek.add(Duration(days: i)));
    }

    return dates;
  }

  /// Gets the age in years from a birth date
  static int getAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;

    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  /// Gets a relative time string (e.g., "2 days ago", "1 week ago")
  static String getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        } else if (difference.inMinutes == 1) {
          return '1 minute ago';
        } else {
          return '${difference.inMinutes} minutes ago';
        }
      } else if (difference.inHours == 1) {
        return '1 hour ago';
      } else {
        return '${difference.inHours} hours ago';
      }
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 14) {
      return '1 week ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks weeks ago';
    } else if (difference.inDays < 60) {
      return '1 month ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months months ago';
    } else if (difference.inDays < 730) {
      return '1 year ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years years ago';
    }
  }

  /// Gets the name of the month
  static String getMonthName(int month, {bool abbreviated = false}) {
    const fullMonths = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    const shortMonths = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    if (month < 1 || month > 12) return '';
    return abbreviated ? shortMonths[month - 1] : fullMonths[month - 1];
  }

  /// Gets the name of the day of week
  static String getDayName(int weekday, {bool abbreviated = false}) {
    const fullDays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];

    const shortDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    if (weekday < 1 || weekday > 7) return '';
    return abbreviated ? shortDays[weekday - 1] : fullDays[weekday - 1];
  }

  /// Converts weeks to a human-readable string (e.g., "2 months, 1 week")
  static String weeksToHumanReadable(int weeks) {
    if (weeks == 0) return '0 weeks';
    if (weeks < 0) return 'Invalid';

    if (weeks < 4) return '$weeks ${weeks == 1 ? 'week' : 'weeks'}';

    final years = weeks ~/ 52;
    final remainingWeeksAfterYears = weeks % 52;
    final months = remainingWeeksAfterYears ~/ 4;
    final remainingWeeks = remainingWeeksAfterYears % 4;

    List<String> parts = [];

    if (years > 0) {
      parts.add('$years ${years == 1 ? 'year' : 'years'}');
    }

    if (months > 0) {
      parts.add('$months ${months == 1 ? 'month' : 'months'}');
    }

    if (remainingWeeks > 0) {
      parts.add('$remainingWeeks ${remainingWeeks == 1 ? 'week' : 'weeks'}');
    }

    if (parts.isEmpty) return '0 weeks';

    if (parts.length == 1) return parts[0];
    if (parts.length == 2) return '${parts[0]} and ${parts[1]}';

    // For 3 parts (years, months, weeks)
    return '${parts[0]}, ${parts[1]} and ${parts[2]}';
  }

  /// Checks if a date is in the future
  static bool isFuture(DateTime date) {
    return date.isAfter(DateTime.now());
  }

  /// Checks if a date is in the past
  static bool isPast(DateTime date) {
    return date.isBefore(DateTime.now());
  }

  /// Gets the next occurrence of a specific weekday
  static DateTime getNextWeekday(int weekday) {
    final now = DateTime.now();
    final daysUntilWeekday = (weekday - now.weekday) % 7;

    if (daysUntilWeekday == 0) {
      // Today is the weekday, get next week's occurrence
      return now.add(Duration(days: 7));
    }

    return now.add(Duration(days: daysUntilWeekday));
  }

  /// Calculates milestone dates based on surgery date and expected progress
  static Map<String, DateTime> getMilestoneDates(DateTime surgeryDate) {
    return {
      'Week 1': surgeryDate.add(Duration(days: 7)),
      'Month 1': surgeryDate.add(Duration(days: 28)),
      'Month 3': surgeryDate.add(Duration(days: 84)),
      'Month 6': surgeryDate.add(Duration(days: 168)),
      'Month 12': surgeryDate.add(Duration(days: 365)),
      '18 Months': surgeryDate.add(Duration(days: 547)),
      '2 Years': surgeryDate.add(Duration(days: 730)),
    };
  }

  /// Gets the current milestone based on weeks post-op
  static String getCurrentMilestone(int weeksPostOp) {
    if (weeksPostOp < 1) return 'Surgery Day';
    if (weeksPostOp < 4) return 'Early Recovery (Weeks 1-4)';
    if (weeksPostOp < 12) return 'Initial Weight Loss (Months 1-3)';
    if (weeksPostOp < 24) return 'Rapid Weight Loss (Months 3-6)';
    if (weeksPostOp < 52) return 'Continued Loss (Months 6-12)';
    if (weeksPostOp < 78) return 'Final Loss Phase (12-18 Months)';
    if (weeksPostOp < 104) return 'Stabilization (18-24 Months)';
    return 'Maintenance Phase (2+ Years)';
  }

  /// Validates if a date is within reasonable bounds for surgery
  static bool isValidSurgeryDate(DateTime date) {
    final now = DateTime.now();
    final fiveYearsAgo = now.subtract(Duration(days: 1825)); // 5 years
    final oneMonthFromNow = now.add(Duration(days: 30)); // Allow future dates up to 1 month

    return date.isAfter(fiveYearsAgo) && date.isBefore(oneMonthFromNow);
  }

  /// Validates if a weight entry date is reasonable
  static bool isValidWeightEntryDate(DateTime date, DateTime? surgeryDate) {
    final now = DateTime.now();

    // Cannot be in the future
    if (date.isAfter(now)) return false;

    // Cannot be more than 5 years ago
    final fiveYearsAgo = now.subtract(Duration(days: 1825));
    if (date.isBefore(fiveYearsAgo)) return false;

    // If surgery date is provided, cannot be more than 1 year before surgery
    if (surgeryDate != null) {
      final oneYearBeforeSurgery = surgeryDate.subtract(Duration(days: 365));
      if (date.isBefore(oneYearBeforeSurgery)) return false;
    }

    return true;
  }
}