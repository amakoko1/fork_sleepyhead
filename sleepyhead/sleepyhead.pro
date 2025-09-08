#-------------------------------------------------
#
# Project created by QtCreator 2011-06-20T22:05:30
#
#-------------------------------------------------

lessThan(QT_MAJOR_VERSION,5)|lessThan(QT_MINOR_VERSION,9) {
    error("You need to Qt 5.9 or newer to build SleepyHead");
}

QT += core gui network xml printsupport serialport widgets help

DEFINES += QT_DEPRECATED_WARNINGS

#SleepyHead requires OpenGL 2.0 support to run smoothly
#On platforms where it's not available, it can still be built to work
#provided the BrokenGL DEFINES flag is passed to qmake (eg, qmake [specs] /path/to/SleepyHeadQT.pro DEFINES+=BrokenGL) (hint, Projects button on the left)
contains(DEFINES, NoGL) {
    message("Building with QWidget gGraphView to support systems without ANY OpenGL")
    DEFINES += BROKEN_OPENGL_BUILD
    DEFINES += NO_OPENGL_BUILD
} else:contains(DEFINES, BrokenGL) {
    DEFINES += BROKEN_OPENGL_BUILD
    message("Building with QWidget gGraphView to support systems with legacy graphics")
    DEFINES-=BrokenGL
} else {
    QT += opengl
    message("Building with regular OpenGL gGraphView")
}

DEFINES += LOCK_RESMED_SESSIONS

CONFIG += c++11
CONFIG += rtti
CONFIG -= debug_and_release

contains(DEFINES, STATIC) {
    static {
        CONFIG += static
        QTPLUGIN += qgif qpng

        message("Static build.")
    }
}

TARGET = SleepyHead
unix:!macx:!haiku {
    TARGET.path=/usr/bin
}

TEMPLATE = app

gitinfotarget.target = git_info.h
gitinfotarget.depends = FORCE

win32 {
    system("$$_PRO_FILE_PWD_/update_gitinfo.bat");
    gitinfotarget.commands = "$$_PRO_FILE_PWD_/update_gitinfo.bat"
} else {
    system("/bin/bash $$_PRO_FILE_PWD_/update_gitinfo.sh");
    gitinfotarget.commands = "/bin/bash $$_PRO_FILE_PWD_/update_gitinfo.sh"
}

PRE_TARGETDEPS += git_info.h
QMAKE_EXTRA_TARGETS += gitinfotarget

#Build the help documentation
message("Generating help files");
qtPrepareTool(QCOLGENERATOR, qcollectiongenerator)

command=$$QCOLGENERATOR $$PWD/help/index.qhcp -o $$PWD/help/index.qhc
system($$command)|error("Failed to run: $$command")
message("Finished generating help files");

macx {
  QMAKE_MACOSX_DEPLOYMENT_TARGET = 10.7
  LIBS             += -lz
  ICON              = icons/iconfile.icns
} else:haiku {
    LIBS            += -lz -lGLU
    DEFINES         += _TTY_POSIX_
} else:unix {
    LIBS            += -lX11 -lz -lGLU
    DEFINES         += _TTY_POSIX_
} else:win32 {
    DEFINES          += WINVER=0x0501 # needed for mingw to pull in appropriate dbt business...probably a better way to do this
    LIBS             += -lsetupapi

    QMAKE_TARGET_PRODUCT = SleepyHead
    QMAKE_TARGET_COMPANY = Jedimark
    QMAKE_TARGET_COPYRIGHT = Copyright (c)2011-2018 Mark Watkins
    QMAKE_TARGET_DESCRIPTION = "OpenSource CPAP Research & Review"
    VERSION = 1.1.0.0
    RC_ICONS = ./icons/bob-v3.0.ico

    INCLUDEPATH += $$PWD
    INCLUDEPATH += $$[QT_INSTALL_PREFIX]/../src/qtbase/src/3rdparty/zlib

    if (*-msvc*):!equals(TEMPLATE_PREFIX, "vc") {
        LIBS += -ladvapi32
    } else {
        # MingW needs this
        LIBS += -lz
    }

    if (*-msvc*) {
        CONFIG += precompile_header
        PRECOMPILED_HEADER = pch.h
        HEADERS += pch.h

    }

    CONFIG(release, debug|release) {
        contains(DEFINES, OfficialBuild) {
           QMAKE_POST_LINK += "$$PWD/../../scripts/release_tool.sh --testing --source \"$$PWD/..\" --binary \"$${OUT_PWD}/$${TARGET}.exe\""
        }
    }
}

TRANSLATIONS = $$files($$PWD/../Translations/*.ts)
qtPrepareTool(LRELEASE, lrelease)

for(file, TRANSLATIONS) {

 qmfile = $$absolute_path($$basename(file), $$PWD/translations/)
 qmfile ~= s,.ts$,.qm,

 qmdir = $$PWD/translations

 !exists($$qmdir) {
     mkpath($$qmdir)|error("Aborting.")
 }
 qmout = $$qmfile
 command = $$LRELEASE -removeidentical $$file -qm $$qmfile
 system($$command)|error("Failed to run: $$command")
 TRANSLATIONS_FILES += $$qmfile
}

#copy the Translation and Help files to where the test binary wants them
macx {
    HelpFiles.files = $$files($$PWD/help/*.qch)
    HelpFiles.path = Contents/Resources/Help
    QMAKE_BUNDLE_DATA += TransFiles
    QMAKE_BUNDLE_DATA += HelpFiles
    message("Setting up Translations & Help Transfers")
} else {
    DDIR = $$OUT_PWD/Translations
    HELPDIR = $$OUT_PWD/Help

    TRANS_FILES += $$PWD/translations/*.qm
    HELP_FILES += $$PWD/help/*.qch

    win32 {
        TRANS_FILES_WIN = $${TRANS_FILES}
        HELP_FILES_WIN = $${HELP_FILES}
        TRANS_FILES_WIN ~= s,/,\\,g
        HELP_FILES_WIN ~= s,/,\\,g
        DDIR ~= s,/,\\,g
        HELPDIR ~= s,/,\\,g

        !exists($$quote($$HELPDIR)): system(mkdir $$quote($$HELPDIR))
        !exists($$quote($$DDIR)): system(mkdir $$quote($$DDIR))

        for(FILE,TRANS_FILES_WIN) {
            system(xcopy /y $$quote($$FILE) $$quote($$DDIR))
        }
        for(FILE,HELP_FILES_WIN) {
            system(xcopy /y $$quote($$FILE) $$quote($$HELPDIR))
        }
    } else {
        system(md $$quote($$HELPDIR))
        system(md $$quote($$DDIR))

        for(FILE,TRANS_FILES_WIN) {
            system(copy $$quote($$FILE) $$quote($$DDIR))
        }
        for(FILE,HELP_FILES_WIN) {
            system(copy $$quote($$FILE) $$quote($$HELPDIR))
        }
    }
}

SOURCES += \
    common_gui.cpp \
    daily.cpp \
    exportcsv.cpp \
    main.cpp \
    mainwindow.cpp \
    newprofile.cpp \
    overview.cpp \
    preferencesdialog.cpp \
    profileselect.cpp \
    reports.cpp \
    sessionbar.cpp \
    updateparser.cpp \
    UpdaterWindow.cpp \
    Graphs/gFlagsLine.cpp \
    Graphs/gFooBar.cpp \
    Graphs/gGraph.cpp \
    Graphs/gGraphView.cpp \
    Graphs/glcommon.cpp \
    Graphs/gLineChart.cpp \
    Graphs/gLineOverlay.cpp \
    Graphs/gSegmentChart.cpp \
    Graphs/gspacer.cpp \
    Graphs/gStatsLine.cpp \
    Graphs/gSummaryChart.cpp \
    Graphs/gXAxis.cpp \
    Graphs/gYAxis.cpp \
    Graphs/layer.cpp \
    SleepLib/calcs.cpp \
    SleepLib/common.cpp \
    SleepLib/day.cpp \
    SleepLib/event.cpp \
    SleepLib/machine.cpp \
    SleepLib/machine_loader.cpp \
    SleepLib/preferences.cpp \
    SleepLib/profiles.cpp \
    SleepLib/schema.cpp \
    SleepLib/session.cpp \
    SleepLib/loader_plugins/cms50_loader.cpp \
    SleepLib/loader_plugins/icon_loader.cpp \
    SleepLib/loader_plugins/intellipap_loader.cpp \
    SleepLib/loader_plugins/mseries_loader.cpp \
    SleepLib/loader_plugins/prs1_loader.cpp \
    SleepLib/loader_plugins/resmed_loader.cpp \
    SleepLib/loader_plugins/somnopose_loader.cpp \
    SleepLib/loader_plugins/zeo_loader.cpp \
    translation.cpp \
    statistics.cpp \
    oximeterimport.cpp \
    SleepLib/serialoximeter.cpp \
    SleepLib/loader_plugins/md300w1_loader.cpp \
    Graphs/gSessionTimesChart.cpp \
    logger.cpp \
    SleepLib/machine_common.cpp \
    SleepLib/loader_plugins/weinmann_loader.cpp \
    Graphs/gdailysummary.cpp \
    Graphs/MinutesAtPressure.cpp \
    SleepLib/journal.cpp \
    SleepLib/progressdialog.cpp \
    SleepLib/loader_plugins/cms50f37_loader.cpp \
    profileselector.cpp \
    SleepLib/loader_plugins/edfparser.cpp \
    aboutdialog.cpp \
    welcome.cpp \
    help.cpp

HEADERS  += \
    common_gui.h \
    daily.h \
    exportcsv.h \
    mainwindow.h \
    newprofile.h \
    overview.h \
    preferencesdialog.h \
    profileselect.h \
    reports.h \
    sessionbar.h \
    updateparser.h \
    UpdaterWindow.h \
    version.h \
    Graphs/gFlagsLine.h \
    Graphs/gFooBar.h \
    Graphs/gGraph.h \
    Graphs/gGraphView.h \
    Graphs/glcommon.h \
    Graphs/gLineChart.h \
    Graphs/gLineOverlay.h \
    Graphs/gSegmentChart.h\
    Graphs/gspacer.h \
    Graphs/gStatsLine.h \
    Graphs/gSummaryChart.h \
    Graphs/gXAxis.h \
    Graphs/gYAxis.h \
    Graphs/layer.h \
    SleepLib/calcs.h \
    SleepLib/common.h \
    SleepLib/day.h \
    SleepLib/event.h \
    SleepLib/machine.h \
    SleepLib/machine_common.h \
    SleepLib/machine_loader.h \
    SleepLib/preferences.h \
    SleepLib/profiles.h \
    SleepLib/schema.h \
    SleepLib/session.h \
    SleepLib/loader_plugins/cms50_loader.h \
    SleepLib/loader_plugins/icon_loader.h \
    SleepLib/loader_plugins/intellipap_loader.h \
    SleepLib/loader_plugins/mseries_loader.h \
    SleepLib/loader_plugins/prs1_loader.h \
    SleepLib/loader_plugins/resmed_loader.h \
    SleepLib/loader_plugins/somnopose_loader.h \
    SleepLib/loader_plugins/zeo_loader.h \
    translation.h \
    statistics.h \
    oximeterimport.h \
    SleepLib/serialoximeter.h \
    SleepLib/loader_plugins/md300w1_loader.h \
    Graphs/gSessionTimesChart.h \
    logger.h \
    SleepLib/loader_plugins/weinmann_loader.h \
    Graphs/gdailysummary.h \
    Graphs/MinutesAtPressure.h \
    SleepLib/journal.h \
    SleepLib/progressdialog.h \
    SleepLib/loader_plugins/cms50f37_loader.h \
    build_number.h \
    profileselector.h \
    SleepLib/appsettings.h \
    SleepLib/loader_plugins/edfparser.h \
    aboutdialog.h \
    welcome.h \
    mytextbrowser.h \
    help.h \
    git_info.h

FORMS += \
    daily.ui \
    overview.ui \
    mainwindow.ui \
    oximetry.ui \
    preferencesdialog.ui \
    report.ui \
    profileselect.ui \
    newprofile.ui \
    exportcsv.ui \
    UpdaterWindow.ui \
    oximeterimport.ui \
    profileselector.ui \
    aboutdialog.ui \
    welcome.ui \
    help.ui

RESOURCES += \
    Resources.qrc

OTHER_FILES += \
    docs/index.html \
    docs/schema.xml \
    docs/graphs.xml \
    docs/channels.xml \
    docs/release_notes.html \
    docs/startup_tips.txt \
    docs/countries.txt \
    docs/tz.txt \
    ../LICENSE.txt \
    docs/tooltips.css \
    docs/script.js \
    ../update.xml \
    docs/changelog.txt \
    docs/intro.html \
    docs/statistics.xml \
    update_gitinfo.bat \
    update_gitinfo.sh

DISTFILES += \
    ../README \
    help/default.css \
    help/help_en/daily.html \
    help/help_en/glossary.html \
    help/help_en/import.html \
    help/help_en/index.html \
    help/help_en/overview.html \
    help/help_en/oximetry.html \
    help/help_en/statistics.html \
    help/help_en/supported.html \
    help/help_en/gettingstarted.html \
    help/help_en/tipsntricks.html \
    help/help_en/faq.html \
    help/help_nl/daily.html \
    help/help_nl/faq.html \
    help/help_nl/gettingstarted.html \
    help/help_nl/glossary.html \
    help/help_nl/import.html \
    help/help_nl/index.html \
    help/help_nl/overview.html \
    help/help_nl/oximetry.html \
    help/help_nl/statistics.html \
    help/help_nl/supported.html \
    help/help_nl/tipsntricks.html \
    help/help_en/reportingbugs.html \
    win_icon.rc \
    help/help_nl/SleepyHeadGuide_nl.qhp \
    help/help_en/SleepyHeadGuide_en.qhp \
    help/index.qhcp
