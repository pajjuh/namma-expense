package com.example.nammaexpense

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class NammaWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                // Background color (adjust for dark mode as needed)
                val balance = widgetData.getString("filtered_balance", "0")
                val income = widgetData.getString("filtered_income", "0")
                val expense = widgetData.getString("filtered_expense", "0")
                val filter = widgetData.getString("current_filter", "Month")
                
                // Set the text from SharedPreferences (data saved from Flutter)
                setTextViewText(R.id.tv_balance, "₹ $balance")
                setTextViewText(R.id.tv_income, "₹ $income")
                setTextViewText(R.id.tv_expense, "₹ $expense")
                setTextViewText(R.id.tv_filter, filter)
            }
            
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
