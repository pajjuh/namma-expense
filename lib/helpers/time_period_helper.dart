import 'package:flutter/material.dart';

class TimeRange {
  final DateTime start;
  final DateTime end;

  TimeRange(this.start, this.end);

  bool contains(DateTime date) {
    return date.isAfter(start.subtract(const Duration(seconds: 1))) && 
           date.isBefore(end.add(const Duration(seconds: 1)));
  }
}

class TimePeriodHelper {
  static int _daysInMonth(int year, int month) {
    // 0 returns the last day of the previous month.
    return DateTime(year, month + 1, 0).day;
  }

  static TimeRange getWeekRange(DateTime now, int startOfWeek) {
    // startOfWeek: 1 = Monday, ..., 7 = Sunday
    // now.weekday is 1-7
    int daysToSubtract = now.weekday - startOfWeek;
    if (daysToSubtract < 0) {
      daysToSubtract += 7;
    }
    final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysToSubtract));
    final end = start.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    return TimeRange(start, end);
  }

  static TimeRange getMonthRange(DateTime now, int startOfMonthDay) {
    // We want the current period based on now.
    // If now.day < startOfMonthDay, the period started last month.
    // Ensure day doesn't exceed days in the target month
    
    int year = now.year;
    int month = now.month;
    
    // Check if the current date is before the start day of the CURRENT month
    // E.g., now = March 5, startOfMonth = 10. Start date should be Feb 10.
    if (now.day < startOfMonthDay) {
      month -= 1;
      if (month < 1) {
        month = 12;
        year -= 1;
      }
    }
    
    int actualStartDay = startOfMonthDay;
    int maxDays = _daysInMonth(year, month);
    if (actualStartDay > maxDays) actualStartDay = maxDays;
    
    final start = DateTime(year, month, actualStartDay);
    
    // End is the next month's start day - 1 second
    int endMonth = month + 1;
    int endYear = year;
    if (endMonth > 12) {
      endMonth = 1;
      endYear += 1;
    }
    
    int actualEndDay = startOfMonthDay;
    int endMaxDays = _daysInMonth(endYear, endMonth);
    if (actualEndDay > endMaxDays) actualEndDay = endMaxDays;
    
    final end = DateTime(endYear, endMonth, actualEndDay).subtract(const Duration(seconds: 1));
    return TimeRange(start, end);
  }

  // Generate historical "month" start dates for the stats screen selector
  // e.g., if now is March 15, and startOfMonth=10, 
  // index 0 = Feb 10 - Mar 9 (Current)
  // index 1 = Jan 10 - Feb 9 (Previous)
  static DateTime getHistoricalMonthStart(DateTime now, int monthsAgo, int startOfMonthDay) {
    int year = now.year;
    int month = now.month;
    
    if (now.day < startOfMonthDay) {
      month -= 1;
    }
    month -= monthsAgo;
    
    while (month < 1) {
      month += 12;
      year -= 1;
    }
    
    int actualStartDay = startOfMonthDay;
    int maxDays = _daysInMonth(year, month);
    if (actualStartDay > maxDays) actualStartDay = maxDays;
    
    return DateTime(year, month, actualStartDay);
  }

  static TimeRange getYearRange(DateTime now, int startOfYearMonth) {
    int year = now.year;
    if (now.month < startOfYearMonth) {
      year -= 1;
    }
    final start = DateTime(year, startOfYearMonth, 1);
    final end = DateTime(year + 1, startOfYearMonth, 1).subtract(const Duration(seconds: 1));
    return TimeRange(start, end);
  }
}
