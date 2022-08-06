# my_ujk_sip

需要在ios文件夹里添加Frameworks文件夹，再在里面加入PortSIPVoIPSDK.framework第三方插件方能使用

需要在android下的build.gradle里添加
rootProject.allprojects {
    repositories {
        flatDir {
            // 由于Library module中引用了 gif 库的 aar，在多 module 的情况下，
            // 其他的module编译会报错，所以需要在所有工程的repositories
            // 下把Library module中的libs目录添加到依赖关系中
            dirs project(':my_ujk_sip').file('libs')
        }
        google()
        mavenCentral()
    }
}

在AndroidManifest.xml中的application里添加：tools:replace="android:label"
如果已经存在一个tools:replace，那就写成tools:replace="xxx,android:label"(xxx表示是其他参数)

