package kr.workon.workon

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * 작업온 홈 화면 위젯(AppWidget).
 *
 * - 데이터는 앱(Flutter)이 home_widget 으로 공유 저장한 [SharedPreferences] 를 그대로 렌더만 한다
 *   (위젯은 네트워크 호출 없음). 문구는 앱 언어 설정에 맞춰 이미 렌더된 문자열이다.
 * - 크기에 따라 2x2(미수금 중심)/4x2(일정+미수금) 레이아웃을 선택한다.
 * - 로그아웃 시 앱이 state="out" 을 저장 → "로그인해 주세요" 화면.
 * - 탭하면 앱을 연다.
 */
class WorkonWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (widgetId in appWidgetIds) {
            val options = appWidgetManager.getAppWidgetOptions(widgetId)
            val views = buildViews(context, widgetData, options)
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    // 리사이즈 시에도 알맞은 레이아웃으로 다시 그린다.
    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        val widgetData =
            context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val views = buildViews(context, widgetData, newOptions)
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun buildViews(
        context: Context,
        data: SharedPreferences,
        options: Bundle?,
    ): RemoteViews {
        val state = data.getString("workon_state", "out")
        val launch = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)

        if (state != "in") {
            val views = RemoteViews(context.packageName, R.layout.workon_widget_login)
            views.setTextViewText(
                R.id.lo_login,
                data.getString("workon_login_please", "로그인해 주세요"),
            )
            views.setOnClickPendingIntent(R.id.workon_widget_root, launch)
            return views
        }

        val minWidth = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0) ?: 0
        // ~4셀(약 250dp) 이상이면 중형, 아니면 소형.
        return if (minWidth >= 250) mediumViews(context, data, launch)
        else smallViews(context, data, launch)
    }

    private fun smallViews(
        context: Context,
        data: SharedPreferences,
        launch: android.app.PendingIntent,
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.workon_widget_small)
        views.setTextViewText(
            R.id.sm_out_label,
            data.getString("workon_outstanding_label", "이번 달 미수금"),
        )
        views.setTextViewText(
            R.id.sm_amount,
            data.getString("workon_outstanding_amount", "0원"),
        )
        views.setTextViewText(R.id.sm_synced, data.getString("workon_synced", ""))
        views.setOnClickPendingIntent(R.id.workon_widget_root, launch)
        return views
    }

    private fun mediumViews(
        context: Context,
        data: SharedPreferences,
        launch: android.app.PendingIntent,
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.workon_widget_medium)
        views.setTextViewText(
            R.id.md_today_label,
            data.getString("workon_today_label", "오늘 일정"),
        )
        views.setTextViewText(
            R.id.md_out_label,
            data.getString("workon_outstanding_label", "이번 달 미수금"),
        )
        views.setTextViewText(
            R.id.md_amount,
            data.getString("workon_outstanding_amount", "0원"),
        )
        views.setTextViewText(R.id.md_synced, data.getString("workon_synced", ""))

        val site = data.getString("workon_today_site", "") ?: ""
        val time = data.getString("workon_today_time", "") ?: ""
        if (site.isEmpty()) {
            // 오늘 일정 없음 → 안내 문구, 시간 숨김.
            views.setTextViewText(
                R.id.md_today_site,
                data.getString("workon_no_schedule", "오늘 일정 없음"),
            )
            views.setViewVisibility(R.id.md_today_time, View.GONE)
        } else {
            views.setTextViewText(R.id.md_today_site, site)
            views.setTextViewText(R.id.md_today_time, time)
            views.setViewVisibility(R.id.md_today_time, View.VISIBLE)
        }
        views.setOnClickPendingIntent(R.id.workon_widget_root, launch)
        return views
    }
}
