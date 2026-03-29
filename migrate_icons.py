#!/usr/bin/env python3
"""Replace Material Icons with Phosphor equivalents across all remaining Dart files."""

import re
import sys

PHOSPHOR_IMPORT = "import 'package:phosphor_flutter/phosphor_flutter.dart';"

# Complete mapping: Icons.xxx -> PhosphorIconsWeight.name
MAPPING = {
    "Icons.access_time": "PhosphorIconsRegular.clock",
    "Icons.access_time_rounded": "PhosphorIconsRegular.clock",
    "Icons.access_time_filled_rounded": "PhosphorIconsFill.clock",
    "Icons.add": "PhosphorIconsRegular.plus",
    "Icons.add_rounded": "PhosphorIconsRegular.plus",
    "Icons.add_circle_outline": "PhosphorIconsRegular.plusCircle",
    "Icons.add_circle_outline_rounded": "PhosphorIconsRegular.plusCircle",
    "Icons.add_photo_alternate_rounded": "PhosphorIconsRegular.imagePlus",
    "Icons.admin_panel_settings_outlined": "PhosphorIconsRegular.shieldStar",
    "Icons.all_inbox_rounded": "PhosphorIconsRegular.tray",
    "Icons.arrow_back": "PhosphorIconsRegular.arrowLeft",
    "Icons.arrow_back_ios_rounded": "PhosphorIconsRegular.arrowLeft",
    "Icons.arrow_back_rounded": "PhosphorIconsRegular.arrowLeft",
    "Icons.arrow_forward": "PhosphorIconsRegular.arrowRight",
    "Icons.arrow_forward_ios_rounded": "PhosphorIconsRegular.arrowRight",
    "Icons.arrow_forward_rounded": "PhosphorIconsRegular.arrowRight",
    "Icons.article_outlined": "PhosphorIconsRegular.article",
    "Icons.article_rounded": "PhosphorIconsRegular.article",
    "Icons.assignment_add": "PhosphorIconsRegular.clipboardText",
    "Icons.assignment_outlined": "PhosphorIconsRegular.clipboard",
    "Icons.assignment_rounded": "PhosphorIconsRegular.clipboard",
    "Icons.attach_file_rounded": "PhosphorIconsRegular.paperclip",
    "Icons.badge_outlined": "PhosphorIconsRegular.identificationCard",
    "Icons.badge_rounded": "PhosphorIconsFill.identificationCard",
    "Icons.bar_chart_rounded": "PhosphorIconsRegular.chartBar",
    "Icons.block": "PhosphorIconsRegular.prohibit",
    "Icons.bolt_rounded": "PhosphorIconsRegular.lightning",
    "Icons.broken_image_outlined": "PhosphorIconsRegular.imageBroken",
    "Icons.broken_image_rounded": "PhosphorIconsRegular.imageBroken",
    "Icons.bug_report_outlined": "PhosphorIconsRegular.bug",
    "Icons.build": "PhosphorIconsRegular.wrench",
    "Icons.business_center_rounded": "PhosphorIconsRegular.briefcase",
    "Icons.business_rounded": "PhosphorIconsRegular.buildings",
    "Icons.calendar_month_outlined": "PhosphorIconsRegular.calendarBlank",
    "Icons.calendar_today": "PhosphorIconsRegular.calendarBlank",
    "Icons.calendar_today_outlined": "PhosphorIconsRegular.calendarBlank",
    "Icons.calendar_today_rounded": "PhosphorIconsRegular.calendarBlank",
    "Icons.calendar_view_week_rounded": "PhosphorIconsRegular.calendarDots",
    "Icons.camera_alt_rounded": "PhosphorIconsRegular.camera",
    "Icons.campaign_outlined": "PhosphorIconsRegular.megaphone",
    "Icons.campaign_rounded": "PhosphorIconsFill.megaphone",
    "Icons.cancel": "PhosphorIconsRegular.xCircle",
    "Icons.cancel_outlined": "PhosphorIconsRegular.xCircle",
    "Icons.cancel_rounded": "PhosphorIconsRegular.xCircle",
    "Icons.category_rounded": "PhosphorIconsRegular.squaresFour",
    "Icons.celebration_rounded": "PhosphorIconsRegular.confetti",
    "Icons.chat_bubble_outline": "PhosphorIconsRegular.chatCircle",
    "Icons.chat_bubble_outline_rounded": "PhosphorIconsRegular.chatCircle",
    "Icons.chat_bubble_rounded": "PhosphorIconsFill.chatCircle",
    "Icons.check": "PhosphorIconsRegular.check",
    "Icons.check_rounded": "PhosphorIconsRegular.check",
    "Icons.check_circle": "PhosphorIconsFill.checkCircle",
    "Icons.check_circle_rounded": "PhosphorIconsFill.checkCircle",
    "Icons.check_circle_outline": "PhosphorIconsRegular.checkCircle",
    "Icons.check_circle_outline_rounded": "PhosphorIconsRegular.checkCircle",
    "Icons.chevron_left": "PhosphorIconsRegular.caretLeft",
    "Icons.chevron_left_rounded": "PhosphorIconsRegular.caretLeft",
    "Icons.chevron_right": "PhosphorIconsRegular.caretRight",
    "Icons.chevron_right_rounded": "PhosphorIconsRegular.caretRight",
    "Icons.child_care": "PhosphorIconsRegular.baby",
    "Icons.circle_outlined": "PhosphorIconsRegular.circle",
    "Icons.clear": "PhosphorIconsRegular.x",
    "Icons.clear_rounded": "PhosphorIconsRegular.x",
    "Icons.close": "PhosphorIconsRegular.x",
    "Icons.close_rounded": "PhosphorIconsRegular.x",
    "Icons.cloud_off_rounded": "PhosphorIconsRegular.cloudSlash",
    "Icons.comment": "PhosphorIconsRegular.chatText",
    "Icons.credit_card_outlined": "PhosphorIconsRegular.creditCard",
    "Icons.dashboard_rounded": "PhosphorIconsRegular.squaresFour",
    "Icons.date_range_rounded": "PhosphorIconsRegular.calendarDots",
    "Icons.delete": "PhosphorIconsRegular.trash",
    "Icons.delete_outline_rounded": "PhosphorIconsRegular.trash",
    "Icons.delete_sweep_rounded": "PhosphorIconsRegular.trash",
    "Icons.delete_forever_rounded": "PhosphorIconsBold.trash",
    "Icons.description_outlined": "PhosphorIconsRegular.fileText",
    "Icons.description_rounded": "PhosphorIconsRegular.fileText",
    "Icons.directions_car": "PhosphorIconsRegular.car",
    "Icons.domain_rounded": "PhosphorIconsRegular.buildings",
    "Icons.done_all": "PhosphorIconsRegular.checks",
    "Icons.done_all_rounded": "PhosphorIconsRegular.checks",
    "Icons.edit": "PhosphorIconsRegular.pencilSimple",
    "Icons.edit_rounded": "PhosphorIconsRegular.pencilSimple",
    "Icons.edit_outlined": "PhosphorIconsRegular.pencilSimple",
    "Icons.edit_calendar": "PhosphorIconsRegular.calendarPlus",
    "Icons.edit_calendar_outlined": "PhosphorIconsRegular.calendarPlus",
    "Icons.edit_calendar_rounded": "PhosphorIconsRegular.calendarPlus",
    "Icons.edit_note": "PhosphorIconsRegular.notePencil",
    "Icons.edit_note_rounded": "PhosphorIconsRegular.notePencil",
    "Icons.email_outlined": "PhosphorIconsRegular.envelope",
    "Icons.email_rounded": "PhosphorIconsRegular.envelope",
    "Icons.emoji_events_rounded": "PhosphorIconsRegular.trophy",
    "Icons.engineering_rounded": "PhosphorIconsRegular.hardHat",
    "Icons.error_outline_rounded": "PhosphorIconsRegular.warningCircle",
    "Icons.error_rounded": "PhosphorIconsRegular.warningCircle",
    "Icons.event_available": "PhosphorIconsRegular.calendarCheck",
    "Icons.event_busy_outlined": "PhosphorIconsRegular.calendarX",
    "Icons.event_busy_rounded": "PhosphorIconsRegular.calendarX",
    "Icons.event_rounded": "PhosphorIconsRegular.calendarBlank",
    "Icons.favorite_border_rounded": "PhosphorIconsRegular.heart",
    "Icons.favorite_rounded": "PhosphorIconsFill.heart",
    "Icons.filter_list_rounded": "PhosphorIconsRegular.funnel",
    "Icons.fingerprint_rounded": "PhosphorIconsRegular.fingerprint",
    "Icons.flag_rounded": "PhosphorIconsRegular.flag",
    "Icons.forum_rounded": "PhosphorIconsRegular.chats",
    "Icons.gps_off_rounded": "PhosphorIconsRegular.navigationSlash",
    "Icons.group_off_outlined": "PhosphorIconsRegular.prohibit",
    "Icons.group_outlined": "PhosphorIconsRegular.usersThree",
    "Icons.group_rounded": "PhosphorIconsRegular.usersThree",
    "Icons.groups_rounded": "PhosphorIconsRegular.usersThree",
    "Icons.help_outline_rounded": "PhosphorIconsRegular.question",
    "Icons.history": "PhosphorIconsRegular.clockCounterClockwise",
    "Icons.hourglass_empty_rounded": "PhosphorIconsRegular.hourglass",
    "Icons.hourglass_top": "PhosphorIconsRegular.hourglassMedium",
    "Icons.hourglass_top_rounded": "PhosphorIconsRegular.hourglassMedium",
    "Icons.how_to_reg_rounded": "PhosphorIconsRegular.userCheck",
    "Icons.image_rounded": "PhosphorIconsRegular.image",
    "Icons.inbox": "PhosphorIconsRegular.tray",
    "Icons.inbox_rounded": "PhosphorIconsRegular.tray",
    "Icons.info_outline": "PhosphorIconsRegular.info",
    "Icons.info_outline_rounded": "PhosphorIconsRegular.info",
    "Icons.keyboard_arrow_down_rounded": "PhosphorIconsRegular.caretDown",
    "Icons.keyboard_arrow_up_rounded": "PhosphorIconsRegular.caretUp",
    "Icons.keyboard_double_arrow_down_rounded": "PhosphorIconsRegular.caretDoubleDown",
    "Icons.keyboard_double_arrow_up_rounded": "PhosphorIconsRegular.caretDoubleUp",
    "Icons.list_alt_rounded": "PhosphorIconsRegular.listBullets",
    "Icons.location_disabled_rounded": "PhosphorIconsRegular.navigationSlash",
    "Icons.location_off_rounded": "PhosphorIconsRegular.navigationSlash",
    "Icons.location_on_rounded": "PhosphorIconsRegular.mapPin",
    "Icons.lock_outline_rounded": "PhosphorIconsRegular.lock",
    "Icons.lock_reset_outlined": "PhosphorIconsRegular.lockKey",
    "Icons.login_rounded": "PhosphorIconsRegular.signIn",
    "Icons.logout": "PhosphorIconsRegular.signOut",
    "Icons.logout_rounded": "PhosphorIconsRegular.signOut",
    "Icons.manage_accounts_rounded": "PhosphorIconsRegular.userGear",
    "Icons.manage_history_rounded": "PhosphorIconsRegular.clockCounterClockwise",
    "Icons.more_horiz_rounded": "PhosphorIconsRegular.dotsThree",
    "Icons.more_vert_rounded": "PhosphorIconsRegular.dotsThreeVertical",
    "Icons.newspaper_rounded": "PhosphorIconsRegular.newspaper",
    "Icons.notes_rounded": "PhosphorIconsRegular.note",
    "Icons.notifications_active": "PhosphorIconsFill.bellRinging",
    "Icons.notifications_none_rounded": "PhosphorIconsRegular.bell",
    "Icons.notifications_outlined": "PhosphorIconsRegular.bell",
    "Icons.notifications_rounded": "PhosphorIconsFill.bell",
    "Icons.open_in_new_rounded": "PhosphorIconsRegular.arrowSquareOut",
    "Icons.park": "PhosphorIconsRegular.tree",
    "Icons.pending_actions": "PhosphorIconsRegular.clipboardText",
    "Icons.pending_actions_outlined": "PhosphorIconsRegular.clipboardText",
    "Icons.pending_actions_rounded": "PhosphorIconsRegular.clipboardText",
    "Icons.people": "PhosphorIconsRegular.users",
    "Icons.people_alt_rounded": "PhosphorIconsRegular.users",
    "Icons.people_outline_rounded": "PhosphorIconsRegular.users",
    "Icons.people_rounded": "PhosphorIconsRegular.users",
    "Icons.percent_rounded": "PhosphorIconsRegular.percent",
    "Icons.person_add": "PhosphorIconsRegular.userPlus",
    "Icons.person_add_alt_": "PhosphorIconsRegular.userPlus",
    "Icons.person_add_rounded": "PhosphorIconsRegular.userPlus",
    "Icons.person_off_rounded": "PhosphorIconsRegular.userMinus",
    "Icons.person_outline_rounded": "PhosphorIconsRegular.user",
    "Icons.person_remove": "PhosphorIconsRegular.userMinus",
    "Icons.person_remove_rounded": "PhosphorIconsRegular.userMinus",
    "Icons.person_rounded": "PhosphorIconsRegular.user",
    "Icons.phone": "PhosphorIconsRegular.phone",
    "Icons.phone_forwarded_rounded": "PhosphorIconsRegular.phoneOutgoing",
    "Icons.phone_outlined": "PhosphorIconsRegular.phone",
    "Icons.phone_rounded": "PhosphorIconsRegular.phone",
    "Icons.photo_library_rounded": "PhosphorIconsRegular.images",
    "Icons.picture_as_pdf_rounded": "PhosphorIconsRegular.filePdf",
    "Icons.pie_chart_rounded": "PhosphorIconsRegular.chartPie",
    "Icons.play_arrow_rounded": "PhosphorIconsRegular.play",
    "Icons.play_circle_filled_rounded": "PhosphorIconsFill.playCircle",
    "Icons.play_circle_outline_rounded": "PhosphorIconsRegular.playCircle",
    "Icons.pool": "PhosphorIconsRegular.waves",
    "Icons.priority_high_rounded": "PhosphorIconsBold.warning",
    "Icons.privacy_tip_outlined": "PhosphorIconsRegular.shieldCheck",
    "Icons.push_pin_outlined": "PhosphorIconsRegular.pushPin",
    "Icons.push_pin_rounded": "PhosphorIconsFill.pushPin",
    "Icons.receipt_long_rounded": "PhosphorIconsRegular.receipt",
    "Icons.refresh_rounded": "PhosphorIconsRegular.arrowsClockwise",
    "Icons.remove": "PhosphorIconsRegular.minus",
    "Icons.remove_rounded": "PhosphorIconsRegular.minus",
    "Icons.remove_circle_outline": "PhosphorIconsRegular.minusCircle",
    "Icons.restore_rounded": "PhosphorIconsRegular.arrowCounterClockwise",
    "Icons.rocket_launch_rounded": "PhosphorIconsRegular.rocketLaunch",
    "Icons.save": "PhosphorIconsRegular.floppyDisk",
    "Icons.save_rounded": "PhosphorIconsRegular.floppyDisk",
    "Icons.schedule": "PhosphorIconsRegular.clock",
    "Icons.schedule_rounded": "PhosphorIconsRegular.clock",
    "Icons.search": "PhosphorIconsRegular.magnifyingGlass",
    "Icons.search_rounded": "PhosphorIconsRegular.magnifyingGlass",
    "Icons.security_rounded": "PhosphorIconsRegular.shield",
    "Icons.send_rounded": "PhosphorIconsRegular.paperPlaneTilt",
    "Icons.settings_rounded": "PhosphorIconsRegular.gear",
    "Icons.shield_outlined": "PhosphorIconsRegular.shield",
    "Icons.short_text_rounded": "PhosphorIconsRegular.textAlignLeft",
    "Icons.show_chart": "PhosphorIconsRegular.trendUp",
    "Icons.sports_esports": "PhosphorIconsRegular.gameController",
    "Icons.stacked_bar_chart_rounded": "PhosphorIconsRegular.chartBar",
    "Icons.star_rounded": "PhosphorIconsRegular.star",
    "Icons.stop_circle_rounded": "PhosphorIconsRegular.stop",
    "Icons.store_rounded": "PhosphorIconsRegular.storefront",
    "Icons.supervisor_account_rounded": "PhosphorIconsRegular.users",
    "Icons.task_alt": "PhosphorIconsRegular.checkSquare",
    "Icons.task_alt_rounded": "PhosphorIconsRegular.checkSquare",
    "Icons.task_outlined": "PhosphorIconsRegular.clipboardText",
    "Icons.timer_off_rounded": "PhosphorIconsRegular.timerSlash",
    "Icons.title_rounded": "PhosphorIconsRegular.textT",
    "Icons.today": "PhosphorIconsRegular.calendarDot",
    "Icons.today_rounded": "PhosphorIconsRegular.calendarDot",
    "Icons.touch_app_rounded": "PhosphorIconsRegular.handTap",
    "Icons.trending_up_rounded": "PhosphorIconsRegular.trendUp",
    "Icons.undo_rounded": "PhosphorIconsRegular.arrowCounterClockwise",
    "Icons.update_rounded": "PhosphorIconsRegular.arrowsClockwise",
    "Icons.verified_rounded": "PhosphorIconsFill.sealCheck",
    "Icons.verified_user_rounded": "PhosphorIconsFill.shieldCheck",
    "Icons.video_settings_rounded": "PhosphorIconsRegular.videoCamera",
    "Icons.videocam_rounded": "PhosphorIconsRegular.videoCamera",
    "Icons.visibility_off_outlined": "PhosphorIconsRegular.eyeSlash",
    "Icons.visibility_outlined": "PhosphorIconsRegular.eye",
    "Icons.warning": "PhosphorIconsRegular.warning",
    "Icons.warning_amber_rounded": "PhosphorIconsRegular.warning",
    "Icons.wifi_off_rounded": "PhosphorIconsRegular.wifiSlash",
    "Icons.wifi_rounded": "PhosphorIconsRegular.wifiHigh",
    "Icons.wifi": "PhosphorIconsRegular.wifiHigh",
    "Icons.work": "PhosphorIconsRegular.briefcase",
}

FILES = [
    "lib/features/newsfeed/widgets/post_detail_sheet.dart",
    "lib/features/shifts/screens/shifts_screen.dart",
    "lib/features/reports/screens/worker_reports_screen.dart",
    "lib/features/reports/screens/task_summary_report.dart",
    "lib/features/reports/screens/task_distribution_report.dart",
    "lib/features/reports/screens/shift_coverage_report.dart",
    "lib/features/reports/screens/missing_clockout_report.dart",
    "lib/features/home/widgets/glass_hero_card.dart",
    "lib/features/notifications/screens/notification_history_screen.dart",
    "lib/features/attendance/widgets/clock_in_out_widget.dart",
    "lib/features/settings/screens/settings_screen.dart",
    "lib/features/attendance/screens/attendance_correction_screen.dart",
    "lib/features/workers/screens/review_worker_screen.dart",
    "lib/core/widgets/profile_avatar.dart",
    "lib/features/reports/screens/workers_hours_report.dart",
    "lib/features/workers/screens/manage_workers_screen.dart",
    "lib/features/workers/screens/edit_worker_licenses_screen.dart",
    "lib/features/shifts/widgets/worker_shift_card.dart",
    "lib/features/reports/screens/worker_shift_report.dart",
    "lib/features/newsfeed/widgets/video_player_widget.dart",
    "lib/features/workers/widgets/shifts_button.dart",
    "lib/features/workers/screens/users_screen.dart",
    "lib/features/workers/screens/approve_worker_screen.dart",
    "lib/features/tasks/screens/worker_task_details.dart",
    "lib/features/shifts/widgets/shift_card.dart",
]

# Sort longest key first so more-specific patterns match before shorter ones
sorted_keys = sorted(MAPPING.keys(), key=len, reverse=True)


def migrate(filepath):
    with open(filepath, "r", encoding="utf-8") as f:
        original = f.read()

    content = original

    # Replace each Icons.xxx token — only when followed by a non-identifier char
    for key in sorted_keys:
        replacement = MAPPING[key]
        # Use word-boundary-like pattern: Icons.foo not followed by more identifier chars
        pattern = re.escape(key) + r'(?=[^a-zA-Z0-9_])'
        content = re.sub(pattern, replacement, content)

    # Add phosphor import if we made changes and it's not already there
    if content != original and PHOSPHOR_IMPORT not in content:
        # Insert after the last 'import' line in the import block
        lines = content.split("\n")
        last_import = -1
        for i, line in enumerate(lines):
            if line.strip().startswith("import "):
                last_import = i
        if last_import >= 0:
            lines.insert(last_import + 1, PHOSPHOR_IMPORT)
            content = "\n".join(lines)

    if content != original:
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(content)
        return True
    return False


if __name__ == "__main__":
    base = "/Users/samerneiroukh/development/Park-Janana"
    changed = 0
    for rel in FILES:
        path = f"{base}/{rel}"
        try:
            if migrate(path):
                print(f"  ✓ {rel}")
                changed += 1
            else:
                print(f"  - {rel} (no changes)")
        except FileNotFoundError:
            print(f"  ✗ NOT FOUND: {rel}", file=sys.stderr)
    print(f"\n{changed}/{len(FILES)} files updated.")
