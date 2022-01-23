TEMPLATE = app
TARGET = bitcoin-qt
macx:TARGET = "Bitcoin-Qt"
VERSION = 0.11.2
INCLUDEPATH += src src/json src/qt
QT += widgets gui network
DEFINES += QT_GUI BOOST_THREAD_USE_LIB BOOST_SPIRIT_THREADSAFE
CONFIG += no_include_pwd
CONFIG += thread

# for boost 1.37, add -mt to the boost libraries
# use: qmake BOOST_LIB_SUFFIX=-mt
# for boost thread win32 with _win32 sufix
# use: BOOST_THREAD_LIB_SUFFIX=_win32-...
# or when linking against a specific BerkelyDB version: BDB_LIB_SUFFIX=-4.8

# Dependency library locations can be customized with:
#    BOOST_INCLUDE_PATH, BOOST_LIB_PATH, BDB_INCLUDE_PATH,
#    BDB_LIB_PATH, OPENSSL_INCLUDE_PATH and OPENSSL_LIB_PATH respectively

OBJECTS_DIR = build
MOC_DIR = build
UI_DIR = build

# use: qmake "RELEASE=1"
contains(RELEASE, 1) {
    # Mac: compile for maximum compatibility (10.5, 32-bit)
    macx:QMAKE_CXXFLAGS += -mmacosx-version-min=10.5 -arch i386 -isysroot /Developer/SDKs/MacOSX10.5.sdk
    macx:QMAKE_CFLAGS += -mmacosx-version-min=10.5 -arch i386 -isysroot /Developer/SDKs/MacOSX10.5.sdk
    macx:QMAKE_OBJECTIVE_CFLAGS += -mmacosx-version-min=10.5 -arch i386 -isysroot /Developer/SDKs/MacOSX10.5.sdk

    !win32:!macx {
        # Linux: static link and extra security (see: https://wiki.debian.org/Hardening)
        LIBS += -Wl,-Bstatic -Wl,-z,relro -Wl,-z,now
    }
}

!win32 {
    # for extra security against potential buffer overflows: enable GCCs Stack Smashing Protection
    QMAKE_CXXFLAGS *= -fstack-protector-all
    QMAKE_LFLAGS *= -fstack-protector-all
    # Exclude on Windows cross compile with MinGW 4.2.x, as it will result in a non-working executable!
    # This can be enabled for Windows, when we switch to MinGW >= 4.4.x.
}
# for extra security (see: https://wiki.debian.org/Hardening): this flag is GCC compiler-specific
QMAKE_CXXFLAGS *= -D_FORTIFY_SOURCE=2
# for extra security on Windows: enable ASLR and DEP via GCC linker flags
win32:QMAKE_LFLAGS *= -Wl,--dynamicbase -Wl,--nxcompat
# on Windows: enable GCC large address aware linker flag
win32:QMAKE_LFLAGS *= -Wl,--large-address-aware

# use: qmake "USE_QRCODE=1"
# libqrencode (http://fukuchi.org/works/qrencode/index.en.html) must be installed for support
contains(USE_QRCODE, 1) {
    message(Building with QRCode support)
    DEFINES += USE_QRCODE
    LIBS += -lqrencode
}

# use: qmake "USE_UPNP=1" ( enabled by default; default)
#  or: qmake "USE_UPNP=0" (disabled by default)
#  or: qmake "USE_UPNP=-" (not supported)
# miniupnpc (http://miniupnp.free.fr/files/) must be installed for support
contains(USE_UPNP, -) {
    message(Building without UPNP support)
} else {
    message(Building with UPNP support)
    count(USE_UPNP, 0) {
        USE_UPNP=1
    }
    DEFINES += USE_UPNP=$$USE_UPNP STATICLIB
    INCLUDEPATH += $$MINIUPNPC_INCLUDE_PATH
    LIBS += $$join(MINIUPNPC_LIB_PATH,,-L,) -lminiupnpc
    win32:LIBS += -liphlpapi
}

# use: qmake "USE_DBUS=1"
contains(USE_DBUS, 1) {
    message(Building with DBUS (Freedesktop notifications) support)
    DEFINES += USE_DBUS
    QT += dbus
}

contains(BITCOIN_NEED_QT_PLUGINS, 1) {
    DEFINES += BITCOIN_NEED_QT_PLUGINS
    QTPLUGIN += qcncodecs qjpcodecs qtwcodecs qkrcodecs qtaccessiblewidgets
}

contains(ENABLE_WALLET, 1) {
    DEFINES += ENABLE_WALLET
}

INCLUDEPATH += src/leveldb/include src/leveldb/helpers src/secp256k1/include src/secp256k1/src
LIBS += $$PWD/src/leveldb/libleveldb.a $$PWD/src/leveldb/libmemenv.a $$PWD/src/secp256k1/libsecp256k1.a
!win32 {
    # we use QMAKE_CXXFLAGS_RELEASE even without RELEASE=1 because we use RELEASE to indicate linking preferences not -O preferences
    genleveldb.commands = cd $$PWD/src/leveldb && CC=$$QMAKE_CC CXX=$$QMAKE_CXX $(MAKE) OPT=\"$$QMAKE_CXXFLAGS $$QMAKE_CXXFLAGS_RELEASE\" libleveldb.a libmemenv.a
    gensecp256k1.commands = cd $$PWD/src/secp256k1 && CC=$$QMAKE_CC CXX=$$QMAKE_CXX $(MAKE) OPT=\"$$QMAKE_CXXFLAGS $$QMAKE_CXXFLAGS_RELEASE\" libsecp256k1.a
} else {
    # make an educated guess about what the ranlib command is called
    isEmpty(QMAKE_RANLIB) {
        QMAKE_RANLIB = $$replace(QMAKE_STRIP, strip, ranlib)
    }
    LIBS += -lshlwapi
    genleveldb.commands = cd $$PWD/src/leveldb && CC=$$QMAKE_CC CXX=$$QMAKE_CXX TARGET_OS=OS_WINDOWS_CROSSCOMPILE $(MAKE) OPT=\"$$QMAKE_CXXFLAGS $$QMAKE_CXXFLAGS_RELEASE\" libleveldb.a libmemenv.a && $$QMAKE_RANLIB $$PWD/src/leveldb/libleveldb.a && $$QMAKE_RANLIB $$PWD/src/leveldb/libmemenv.a
    gensecp256k1.commands = cd $$PWD/src/secp256k1 && CC=$$QMAKE_CC CXX=$$QMAKE_CXX TARGET_OS=OS_WINDOWS_CROSSCOMPILE $(MAKE) OPT=\"$$QMAKE_CXXFLAGS $$QMAKE_CXXFLAGS_RELEASE\" libsecp256k1.a && $$QMAKE_RANLIB $$PWD/src/secp256k1/libsecp256k1.a
}
genleveldb.target = $$PWD/src/leveldb/libleveldb.a
gensecp256k1.target = $$PWD/src/secp256k1/libsecp256k1.a
genleveldb.depends = FORCE
gensecp256k1.depends = FORCE
PRE_TARGETDEPS += $$PWD/src/leveldb/libleveldb.a $$PWD/src/secp256k1/libsecp256k1.a
QMAKE_EXTRA_TARGETS += genleveldb gensecp256k1
# Gross ugly hack that depends on qmake internals, unfortunately there is no other way to do it.
QMAKE_CLEAN += $$PWD/src/leveldb/libleveldb.a; cd $$PWD/src/leveldb ; $(MAKE) clean
QMAKE_CLEAN += $$PWD/src/secp256k1/libsecp256k1.a; cd $$PWD/src/secp256k1 ; $(MAKE) clean

# regenerate src/build.h
!win32|contains(USE_BUILD_INFO, 1) {
    genbuild.depends = FORCE
    genbuild.commands = cd $$PWD; /bin/sh share/genbuild.sh $$OUT_PWD/build/build.h
    genbuild.target = $$OUT_PWD/build/build.h
    PRE_TARGETDEPS += $$OUT_PWD/build/build.h
    QMAKE_EXTRA_TARGETS += genbuild
    DEFINES += HAVE_BUILD_INFO
}

QMAKE_CXXFLAGS_WARN_ON = -fdiagnostics-show-option -Wall -Wextra -Wformat -Wformat-security -Wno-unused-parameter -Wstack-protector

# Input
DEPENDPATH += src src/json src/qt
HEADERS += src/qt/bitcoinaddressvalidator.h \
    src/qt/bitcoinamountfield.h \
    src/qt/bitcoingui.h \
    src/qt/bitcoinunits.h \
    src/qt/clientmodel.h \
    src/qt/csvmodelwriter.h \
    src/qt/guiconstants.h \
    src/qt/guiutil.h \
    src/qt/intro.h \
    src/qt/macnotificationhandler.h \
    src/qt/networkstyle.h \
    src/qt/notificator.h \
    src/qt/optionsdialog.h \
    src/qt/optionsmodel.h \
    src/qt/paymentrequestplus.h \
    src/qt/peertablemodel.h \
    src/qt/qvalidatedlineedit.h \
    src/qt/qvaluecombobox.h \
    src/qt/rpcconsole.h \
    src/qt/scicon.h \
    src/qt/splashscreen.h \
    src/qt/trafficgraphwidget.h \
    src/qt/transactiondesc.h \
    src/qt/transactionrecord.h \
    src/qt/utilitydialog.h \
    src/qt/walletmodeltransaction.h \
    src/qt/winshutdownmonitor.h \
    src/amount.h \
    src/arith_uint256.h \
    src/base58.h \
    src/bloom.h \
    src/chain.h \
    src/chainparams.h \
    src/chainparamsbase.h \
    src/chainparamsseeds.h \
    src/checkpoints.h \
    src/checkqueue.h \
    src/clientversion.h \
    src/coincontrol.h \
    src/coins.h \
    src/compat.h \
    src/compat/byteswap.h \
    src/compat/endian.h \
    src/compat/sanity.h \
    src/compressor.h \
    src/consensus/consensus.h \
    src/consensus/params.h \
    src/consensus/validation.h \
    src/core_io.h \
    src/eccryptoverify.h \
    src/ecwrapper.h \
    src/hash.h \
    src/init.h \
    src/key.h \
    src/keystore.h \
    src/leveldbwrapper.h \
    src/limitedmap.h \
    src/main.h \
    src/memusage.h \
    src/merkleblock.h \
    src/miner.h \
    src/mruset.h \
    src/net.h \
    src/netbase.h \
    src/noui.h \
    src/policy/fees.h \
    src/pow.h \
    src/primitives/block.h \
    src/primitives/transaction.h \
    src/protocol.h \
    src/pubkey.h \
    src/random.h \
    src/reverselock.h \
    src/rpcclient.h \
    src/rpcprotocol.h \
    src/rpcserver.h \
    src/scheduler.h \
    src/script/interpreter.h \
    src/script/script.h \
    src/script/script_error.h \
    src/script/sigcache.h \
    src/script/sign.h \
    src/script/standard.h \
    src/serialize.h \
    src/streams.h \
    src/support/allocators/secure.h \
    src/support/allocators/zeroafterfree.h \
    src/support/cleanse.h \
    src/support/pagelocker.h \
    src/sync.h \
    src/threadsafety.h \
    src/timedata.h \
    src/tinyformat.h \
    src/txdb.h \
    src/txmempool.h \
    src/ui_interface.h \
    src/uint256.h \
    src/undo.h \
    src/util.h \
    src/utilmoneystr.h \
    src/utilstrencodings.h \
    src/utiltime.h \
    src/validationinterface.h \
    src/version.h \
    src/wallet/crypter.h \
    src/wallet/db.h \
    src/wallet/wallet.h \
    src/wallet/wallet_ismine.h \
    src/wallet/walletdb.h \
    src/crypto/common.h \
    src/crypto/hmac_sha256.h \
    src/crypto/hmac_sha512.h \
    src/crypto/ripemd160.h \
    src/crypto/sha1.h \
    src/crypto/sha256.h \
    src/crypto/sha512.h \
    src/univalue/univalue.h \
    src/univalue/univalue_escapes.h \
    src/json/json_spirit.h \
    src/json/json_spirit_error_position.h \
    src/json/json_spirit_reader.h \
    src/json/json_spirit_reader_template.h \
    src/json/json_spirit_stream_reader.h \
    src/json/json_spirit_utils.h \
    src/json/json_spirit_value.h \
    src/json/json_spirit_writer.h \
    src/json/json_spirit_writer_template.h

contains(ENABLE_WALLET, 1) {
HEADERS += src/qt/paymentserver.h \
    src/qt/receivecoinsdialog.h \
    src/qt/receiverequestdialog.h \
    src/qt/recentrequeststablemodel.h \
    src/qt/sendcoinsdialog.h \
    src/qt/sendcoinsentry.h \
    src/qt/transactionview.h \
    src/qt/transactiondescdialog.h \
    src/qt/transactionfilterproxy.h \
    src/qt/walletmodel.h \
    src/qt/addressbookpage.h \
    src/qt/addresstablemodel.h \
    src/qt/askpassphrasedialog.h \
    src/qt/coincontroldialog.h \
    src/qt/coincontroltreewidget.h \
    src/qt/editaddressdialog.h \
    src/qt/openuridialog.h \
    src/qt/overviewpage.h \
    src/qt/signverifymessagedialog.h \
    src/qt/transactiontablemodel.h \
    src/qt/walletframe.h \
    src/qt/walletview.h
}

SOURCES += src/qt/bitcoinaddressvalidator.cpp \
    src/qt/bitcoinamountfield.cpp \
    src/qt/bitcoingui.cpp \
    src/qt/bitcoinunits.cpp \
    src/qt/clientmodel.cpp \
    src/qt/csvmodelwriter.cpp \
    src/qt/guiutil.cpp \
    src/qt/intro.cpp \
    src/qt/networkstyle.cpp \
    src/qt/notificator.cpp \
    src/qt/optionsdialog.cpp \
    src/qt/optionsmodel.cpp \
    src/qt/peertablemodel.cpp \
    src/qt/qvalidatedlineedit.cpp \
    src/qt/qvaluecombobox.cpp \
    src/qt/rpcconsole.cpp \
    src/qt/scicon.cpp \
    src/qt/splashscreen.cpp \
    src/qt/trafficgraphwidget.cpp \
    src/qt/utilitydialog.cpp

# use: qmake "ENABLE_WALLET=1"
contains(ENABLE_WALLET, 1) {
SOURCES += src/qt/addressbookpage.cpp \
    src/qt/addresstablemodel.cpp \
    src/qt/askpassphrasedialog.cpp \
    src/qt/coincontroldialog.cpp \
    src/qt/coincontroltreewidget.cpp \
    src/qt/editaddressdialog.cpp \
    src/qt/openuridialog.cpp \
    src/qt/overviewpage.cpp \
    src/qt/paymentrequestplus.cpp \
    src/qt/paymentserver.cpp \
    src/qt/receivecoinsdialog.cpp \
    src/qt/receiverequestdialog.cpp \
    src/qt/recentrequeststablemodel.cpp \
    src/qt/sendcoinsdialog.cpp \
    src/qt/sendcoinsentry.cpp \
    src/qt/signverifymessagedialog.cpp \
    src/qt/transactiondesc.cpp \
    src/qt/transactiondescdialog.cpp \
    src/qt/transactionfilterproxy.cpp \
    src/qt/transactionrecord.cpp \
    src/qt/transactiontablemodel.cpp \
    src/qt/transactionview.cpp \
    src/qt/walletframe.cpp \
    src/qt/walletmodel.cpp \
    src/qt/walletmodeltransaction.cpp \
    src/qt/walletview.cpp
}

SOURCES += src/addrman.cpp \
    src/bloom.cpp \
    src/chain.cpp \
    src/checkpoints.cpp \
    src/init.cpp \
    src/leveldbwrapper.cpp \
    src/main.cpp \
    src/merkleblock.cpp \
    src/miner.cpp \
    src/net.cpp \
    src/noui.cpp \
    src/policy/fees.cpp \
    src/pow.cpp \
    src/rest.cpp \
    src/rpcblockchain.cpp \
    src/rpcmining.cpp \
    src/rpcmisc.cpp \
    src/rpcnet.cpp \
    src/rpcrawtransaction.cpp \
    src/rpcserver.cpp \
    src/script/sigcache.cpp \
    src/timedata.cpp \
    src/txdb.cpp \
    src/txmempool.cpp \
    src/validationinterface.cpp \
    src/rpcclient.cpp \
    src/amount.cpp \
    src/arith_uint256.cpp \
    src/base58.cpp \
    src/chainparams.cpp \
    src/coins.cpp \
    src/compressor.cpp \
    src/core_read.cpp \
    src/core_write.cpp \
    src/eccryptoverify.cpp \
    src/ecwrapper.cpp \
    src/hash.cpp \
    src/key.cpp \
    src/keystore.cpp \
    src/netbase.cpp \
    src/primitives/block.cpp \
    src/primitives/transaction.cpp \
    src/protocol.cpp \
    src/pubkey.cpp \
    src/scheduler.cpp \
    src/script/interpreter.cpp \
    src/script/script.cpp \
    src/script/script_error.cpp \
    src/script/sign.cpp \
    src/script/standard.cpp \
    src/support/pagelocker.cpp \
    src/chainparamsbase.cpp \
    src/clientversion.cpp \
    src/compat/glibc_sanity.cpp \
    src/compat/glibcxx_sanity.cpp \
    src/compat/strnlen.cpp \
    src/random.cpp \
    src/rpcprotocol.cpp \
    src/support/cleanse.cpp \
    src/sync.cpp \
    src/uint256.cpp \
    src/util.cpp \
    src/utilmoneystr.cpp \
    src/utilstrencodings.cpp \
    src/utiltime.cpp \
    src/crypto/hmac_sha256.cpp \
    src/crypto/hmac_sha512.cpp \
    src/crypto/ripemd160.cpp \
    src/crypto/sha1.cpp \
    src/crypto/sha256.cpp \
    src/crypto/sha512.cpp \
    src/univalue/univalue.cpp \
    src/univalue/univalue_read.cpp \
    src/univalue/univalue_write.cpp

# use: qmake "ENABLE_WALLET=1"
contains(ENABLE_WALLET, 1) {
SOURCES += src/wallet/crypter.cpp \
    src/wallet/db.cpp \
    src/wallet/rpcdump.cpp \
    src/wallet/rpcwallet.cpp \
    src/wallet/wallet.cpp \
    src/wallet/wallet_ismine.cpp \
    src/wallet/walletdb.cpp
}

# use: qmake "GLIBC_BACK_COMPAT=1"
contains(GLIBC_BACK_COMPAT, 1) {
    SOURCES += src/compat/glibc_compat.cpp
}

system(protoc src/qt/paymentrequest.proto --cpp_out=src/qt/ --proto_path=src/qt/)
HEADERS += src/qt/paymentrequest.pb.h
SOURCES += src/qt/paymentrequest.pb.cc

SOURCES += src/qt/bitcoin.cpp
RESOURCES += src/qt/bitcoin.qrc src/qt/bitcoin_locale.qrc

FORMS += src/qt/forms/addressbookpage.ui \
    src/qt/forms/askpassphrasedialog.ui \
    src/qt/forms/coincontroldialog.ui \
    src/qt/forms/editaddressdialog.ui \
    src/qt/forms/helpmessagedialog.ui \
    src/qt/forms/intro.ui \
    src/qt/forms/openuridialog.ui \
    src/qt/forms/optionsdialog.ui \
    src/qt/forms/overviewpage.ui \
    src/qt/forms/receivecoinsdialog.ui \
    src/qt/forms/receiverequestdialog.ui \
    src/qt/forms/rpcconsole.ui \
    src/qt/forms/sendcoinsdialog.ui \
    src/qt/forms/sendcoinsentry.ui \
    src/qt/forms/signverifymessagedialog.ui \
    src/qt/forms/transactiondescdialog.ui

contains(BITCOIN_QT_TEST, 1) {
SOURCES += src/qt/test/test_main.cpp \
    src/qt/test/uritests.cpp

contains(ENABLE_WALLET, 1) {
    SOURCES += src/qt/test/paymentservertests.cpp
}

HEADERS += src/qt/test/uritests.h \
    src/qt/test/paymentrequestdata.h \
    src/qt/test/paymentservertests.h

DEPENDPATH += src/qt/test
QT += testlib
TARGET = bitcoin-qt_test
DEFINES += BITCOIN_QT_TEST
  macx: CONFIG -= app_bundle
}

CODECFORTR = UTF-8

# for lrelease/lupdate
# also add new translations to src/qt/bitcoin_locale.qrc under translations/
TRANSLATIONS = $$files(src/qt/locale/bitcoin_*.ts)

isEmpty(QMAKE_LRELEASE) {
    win32:QMAKE_LRELEASE = $$[QT_INSTALL_BINS]\\lrelease.exe
    else:QMAKE_LRELEASE = $$[QT_INSTALL_BINS]/lrelease
}
isEmpty(QM_DIR):QM_DIR = $$PWD/src/qt/locale
# automatically build translations, so they can be included in resource file
TSQM.name = lrelease ${QMAKE_FILE_IN}
TSQM.input = TRANSLATIONS
TSQM.output = $$QM_DIR/${QMAKE_FILE_BASE}.qm
TSQM.commands = $$QMAKE_LRELEASE ${QMAKE_FILE_IN} -qm ${QMAKE_FILE_OUT}
TSQM.CONFIG = no_link
QMAKE_EXTRA_COMPILERS += TSQM

# "Other files" to show in Qt Creator
OTHER_FILES += README.md \
    doc/*.rst \
    doc/*.txt \
    src/qt/res/bitcoin-qt.rc \
    src/test/*.cpp \
    src/test/*.h \
    src/qt/test/*.cpp \
    src/qt/test/*.h

# platform specific defaults, if not overridden on command line
isEmpty(BOOST_LIB_SUFFIX) {
    macx:BOOST_LIB_SUFFIX = -mt
    win32:BOOST_LIB_SUFFIX = -mgw44-mt-s-1_50
}

isEmpty(BOOST_THREAD_LIB_SUFFIX) {
    BOOST_THREAD_LIB_SUFFIX = $$BOOST_LIB_SUFFIX
}

isEmpty(BDB_LIB_PATH) {
    macx:BDB_LIB_PATH = /opt/local/lib/db48
}

isEmpty(BDB_LIB_SUFFIX) {
    macx:BDB_LIB_SUFFIX = -4.8
}

isEmpty(BDB_INCLUDE_PATH) {
    macx:BDB_INCLUDE_PATH = /opt/local/include/db48
}

isEmpty(BOOST_LIB_PATH) {
    macx:BOOST_LIB_PATH = /opt/local/lib
}

isEmpty(BOOST_INCLUDE_PATH) {
    macx:BOOST_INCLUDE_PATH = /opt/local/include
}

win32:DEFINES += WIN32
win32:RC_FILE = src/qt/res/bitcoin-qt.rc

win32:!contains(MINGW_THREAD_BUGFIX, 0) {
    # At least qmake's win32-g++-cross profile is missing the -lmingwthrd
    # thread-safety flag. GCC has -mthreads to enable this, but it doesn't
    # work with static linking. -lmingwthrd must come BEFORE -lmingw, so
    # it is prepended to QMAKE_LIBS_QT_ENTRY.
    # It can be turned off with MINGW_THREAD_BUGFIX=0, just in case it causes
    # any problems on some untested qmake profile now or in the future.
    DEFINES += _MT
    QMAKE_LIBS_QT_ENTRY = -lmingwthrd $$QMAKE_LIBS_QT_ENTRY
}

!win32:!macx {
    DEFINES += LINUX
    LIBS += -lrt
    # _FILE_OFFSET_BITS=64 lets 32-bit fopen transparently support large files.
    DEFINES += _FILE_OFFSET_BITS=64
}

macx:HEADERS += src/qt/macdockiconhandler.h src/qt/macnotificationhandler.h
macx:OBJECTIVE_SOURCES += src/qt/macdockiconhandler.mm src/qt/macnotificationhandler.mm
macx:LIBS += -framework Foundation -framework ApplicationServices -framework AppKit
macx:DEFINES += MAC_OSX MSG_NOSIGNAL=0
macx:ICON = src/qt/res/icons/bitcoin.icns
macx:QMAKE_CFLAGS_THREAD += -pthread
macx:QMAKE_LFLAGS_THREAD += -pthread
macx:QMAKE_CXXFLAGS_THREAD += -pthread
macx:QMAKE_INFO_PLIST = share/qt/Info.plist

# Set libraries and includes at end, to use platform-defined defaults if not overridden
INCLUDEPATH += $$BOOST_INCLUDE_PATH $$BDB_INCLUDE_PATH $$OPENSSL_INCLUDE_PATH $$QRENCODE_INCLUDE_PATH
LIBS += $$join(BOOST_LIB_PATH,,-L,) $$join(BDB_LIB_PATH,,-L,) $$join(OPENSSL_LIB_PATH,,-L,) $$join(QRENCODE_LIB_PATH,,-L,)
LIBS += -lssl -lcrypto -ldb_cxx$$BDB_LIB_SUFFIX -lprotobuf
# -lgdi32 has to happen after -lcrypto (see  #681)
win32:LIBS += -lws2_32 -lshlwapi -lmswsock -lole32 -loleaut32 -luuid -lgdi32
LIBS += -lboost_system$$BOOST_LIB_SUFFIX -lboost_filesystem$$BOOST_LIB_SUFFIX -lboost_program_options$$BOOST_LIB_SUFFIX -lboost_thread$$BOOST_THREAD_LIB_SUFFIX -lboost_chrono$$BOOST_THREAD_LIB_SUFFIX

contains(RELEASE, 1) {
    !win32:!macx {
        # Linux: turn dynamic linking back on for c/c++ runtime libraries
        LIBS += -Wl,-Bdynamic
    }
}

system($$QMAKE_LRELEASE -silent $$TRANSLATIONS)
