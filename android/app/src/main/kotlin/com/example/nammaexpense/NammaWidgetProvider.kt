package com.example.nammaexpense

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider

class NammaWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val options = appWidgetManager.getAppWidgetOptions(widgetId)
            updateWidget(context, appWidgetManager, widgetId, widgetData, options)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: android.os.Bundle
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        val widgetData = HomeWidgetPlugin.getData(context)
        updateWidget(context, appWidgetManager, appWidgetId, widgetData, newOptions)
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int,
        widgetData: SharedPreferences,
        options: android.os.Bundle
    ) {
        val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 110)
        val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 110)
        
        // Define horizontally constrained (e.g. 1x2/2x1 shapes)
        val isHorizontal = minWidth >= 110 && minHeight <= 100
        // Define small as Width < 150dp OR Height < 120dp
        val isSmall = minWidth < 150 || minHeight < 120
        
        val layoutId = if (isHorizontal) R.layout.widget_layout_hz
                       else if (isSmall) R.layout.widget_layout_small 
                       else R.layout.widget_layout

        val views = RemoteViews(context.packageName, layoutId).apply {
            val balance = widgetData.getString("filtered_balance", "0")
            val income = widgetData.getString("filtered_income", "0")
            val expense = widgetData.getString("filtered_expense", "0")
            val filter = widgetData.getString("current_filter", "Month")
            
            if (isHorizontal || isSmall) {
                // For horizontal or small layouts, only show expense and filter
                setTextViewText(R.id.tv_expense, "₹ $expense")
                setTextViewText(R.id.tv_filter, filter)
            } else {
                // For regular layout, show all details
                setTextViewText(R.id.tv_balance, "₹ $balance")
                setTextViewText(R.id.tv_income, "₹ $income")
                setTextViewText(R.id.tv_expense, "₹ $expense")
                setTextViewText(R.id.tv_filter, filter)
            }
        }
        
        appWidgetManager.updateAppWidget(widgetId, views)
    }
}
