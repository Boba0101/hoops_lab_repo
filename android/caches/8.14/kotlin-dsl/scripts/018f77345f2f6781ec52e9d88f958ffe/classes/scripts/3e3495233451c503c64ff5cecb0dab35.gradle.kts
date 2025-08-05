                                                           
                                                                         
                             

import org.gradle.api.JavaVersion
import org.jetbrains.kotlin.gradle.plugin.KotlinAndroidPluginWrapper

                                                                          
                                                                            
                                                                      
                                                                     
             
                  
                
                      
     
                  
                                     
                                                                                                            
                                                                                                                  
                                                                                               
                                                                                                 
                                                         
                                                                     
     
 

apply<FlutterDependencyCheckerPlugin>()

class FlutterDependencyCheckerPlugin : Plugin<Project> {
    override fun apply(project: Project) {
        DependencyVersionChecker.checkDependencyVersions(project)
    }
}

class DependencyVersionChecker {
    companion object {
        private const val GRADLE_NAME: String = "Gradle"
        private const val JAVA_NAME: String = "Java"
        private const val AGP_NAME: String = "Android Gradle Plugin"
        private const val KGP_NAME: String = "Kotlin"

                                                                                              
                                                                                           
                                                                                                                                       
        private const val OUT_OF_SUPPORT_RANGE_PROPERTY = "usesUnsupportedDependencyVersions"

                                                                                                   
                                                                                                 
                                                                                     
        private fun getPotentialGradleFix(projectDirectory: String): String {
            return "Your project's gradle version is typically " +
                "defined in the gradle wrapper file. By default, this can be found at " +
                "$projectDirectory/gradle/wrapper/gradle-wrapper.properties. \n" +
                "For more information, see https://docs.gradle.org/current/userguide/gradle_wrapper.html.\n"
        }

                                                                             
                                    
        private const val POTENTIAL_JAVA_FIX: String =
            "The Java version used by Flutter can be " +
                "set with `flutter config --jdk-dir=<path>`. \nFor more information about how Flutter " +
                "chooses which version of Java to use, see the --jdk-dir section of the " +
                "output of `flutter config -h`.\n"

        private fun getPotentialAGPFix(projectDirectory: String): String {
            return "Your project's AGP version is typically " +
                "defined in the plugins block of the `settings.gradle` file " +
                "($projectDirectory/settings.gradle), by a plugin with the id of " +
                "com.android.application. \nIf you don't see a plugins block, your project " +
                "was likely created with an older template version. In this case it is most " +
                "likely defined in the top-level build.gradle file " +
                "($projectDirectory/build.gradle) by the following line in the dependencies" +
                " block of the buildscript: \"classpath 'com.android.tools.build:gradle:<version>'\".\n"
        }

        private fun getPotentialKGPFix(projectDirectory: String): String {
            return "Your project's KGP version is typically " +
                "defined in the plugins block of the `settings.gradle` file " +
                "($projectDirectory/settings.gradle), by a plugin with the id of " +
                "org.jetbrains.kotlin.android. \nIf you don't see a plugins block, your project " +
                "was likely created with an older template version, in which case it is most " +
                "likely defined in the top-level build.gradle file " +
                "($projectDirectory/build.gradle) by the ext.kotlin_version property.\n"
        }

                                                                                           
                                                                                              
                                                                             
                                                               
        val warnGradleVersion: Version = Version(7, 4, 2)
        val errorGradleVersion: Version = Version(7, 0, 2)

        val warnJavaVersion: JavaVersion = JavaVersion.VERSION_11
        val errorJavaVersion: JavaVersion = JavaVersion.VERSION_1_1

        val warnAGPVersion: Version = Version(7, 3, 1)
        val errorAGPVersion: Version = Version(7, 0, 0)

        val warnKGPVersion: Version = Version(1, 8, 10)
        val errorKGPVersion: Version = Version(1, 7, 0)

           
                                                                                                 
                                                                                             
                                                                         
           
        fun checkDependencyVersions(project: Project) {
            project.extra.set(OUT_OF_SUPPORT_RANGE_PROPERTY, false)
            var agpVersion: Version?
            var kgpVersion: Version?

            checkGradleVersion(getGradleVersion(project), project)
            checkJavaVersion(getJavaVersion(), project)
            agpVersion = getAGPVersion(project)
            if (agpVersion != null) {
                checkAGPVersion(agpVersion, project)
            } else {
                project.logger.error(
                    "Warning: unable to detect project AGP version. Skipping " +
                        "version checking. \nThis may be because you have applied AGP after the Flutter Gradle Plugin."
                )
            }

            kgpVersion = getKGPVersion(project)
            if (kgpVersion != null) {
                checkKGPVersion(kgpVersion, project)
            }
                                                                                          
        }

                                                                                                                                              
        fun getGradleVersion(project: Project): Version {
            val untrimmedGradleVersion: String = project.gradle.getGradleVersion()
                                                                                                   
                                                                             
                                        
            return Version.fromString(untrimmedGradleVersion.substringBefore('-'))
        }

                                                                                                                                          
        fun getJavaVersion(): JavaVersion {
            return JavaVersion.current()
        }

                                                                         
                                                                                                                                                                                                                  
        fun getAGPVersion(project: Project): Version? {
            val agpPluginName: String = "com.android.base"
            val agpVersionFieldName: String = "ANDROID_GRADLE_PLUGIN_VERSION"
            var agpVersion: Version?
            try {
                agpVersion =
                    Version.fromString(
                        project.plugins.getPlugin(agpPluginName)::class.java.classLoader.loadClass(
                            com.android.Version::class.java.name
                        ).fields.find { it.name == agpVersionFieldName }!!
                            .get(null) as String
                    )
            } catch (ignored: ClassNotFoundException) {
                                                                                                    
                                               
                @Suppress("deprecation")
                agpVersion =
                    Version.fromString(
                        project.plugins.getPlugin(agpPluginName)::class.java.classLoader.loadClass(
                            com.android.builder.model.Version::class.java.name
                        ).fields.find { it.name == agpVersionFieldName }!!
                            .get(null) as String
                    )
            }
            return agpVersion
        }

        fun getKGPVersion(project: Project): Version? {
            val kotlinVersionProperty: String = "kotlin_version"
            val firstKotlinVersionFieldName: String = "pluginVersion"
            val secondKotlinVersionFieldName: String = "kotlinPluginVersion"
                                                                                          
                                           
            if (project.hasProperty(kotlinVersionProperty)) {
                return Version.fromString(project.properties.get(kotlinVersionProperty) as String)
            }
            val kotlinPlugin =
                project.getPlugins()
                    .findPlugin(KotlinAndroidPluginWrapper::class.java)
            val versionfield =
                kotlinPlugin?.javaClass?.kotlin?.members?.first {
                    it.name == firstKotlinVersionFieldName || it.name == secondKotlinVersionFieldName
                }
            val versionString = versionfield?.call(kotlinPlugin)
            if (versionString == null) {
                return null
            } else {
                return Version.fromString(versionString as String)
            }
        }

        private fun getErrorMessage(
            dependencyName: String,
            versionString: String,
            errorVersion: String,
            potentialFix: String
        ): String {
            return "Error: Your project's $dependencyName version ($versionString) is lower " +
                "than Flutter's minimum supported version of $errorVersion. Please upgrade " +
                "your $dependencyName version. \nAlternatively, use the flag " +
                "\"--android-skip-build-dependency-validation\" to bypass this check.\n\n" +
                "Potential fix: $potentialFix"
        }

        private fun getWarnMessage(
            dependencyName: String,
            versionString: String,
            warnVersion: String,
            potentialFix: String
        ): String {
            return "Warning: Flutter support for your project's $dependencyName version " +
                "($versionString) will soon be dropped. Please upgrade your $dependencyName " +
                "version to a version of at least $warnVersion soon." +
                "\nAlternatively, use the flag \"--android-skip-build-dependency-validation\"" +
                " to bypass this check.\n\nPotential fix: $potentialFix"
        }

        fun checkGradleVersion(
            version: Version,
            project: Project
        ) {
            if (version < errorGradleVersion) {
                val errorMessage: String =
                    getErrorMessage(
                        GRADLE_NAME,
                        version.toString(),
                        errorGradleVersion.toString(),
                        getPotentialGradleFix(project.getRootDir().getPath())
                    )
                project.extra.set(OUT_OF_SUPPORT_RANGE_PROPERTY, true)
                throw DependencyValidationException(errorMessage)
            } else if (version < warnGradleVersion) {
                val warnMessage: String =
                    getWarnMessage(
                        GRADLE_NAME,
                        version.toString(),
                        warnGradleVersion.toString(),
                        getPotentialGradleFix(project.getRootDir().getPath())
                    )
                project.logger.error(warnMessage)
            }
        }

        fun checkJavaVersion(
            version: JavaVersion,
            project: Project
        ) {
            if (version < errorJavaVersion) {
                val errorMessage: String =
                    getErrorMessage(
                        JAVA_NAME,
                        version.toString(),
                        errorJavaVersion.toString(),
                        POTENTIAL_JAVA_FIX
                    )
                project.extra.set(OUT_OF_SUPPORT_RANGE_PROPERTY, true)
                throw DependencyValidationException(errorMessage)
            } else if (version < warnJavaVersion) {
                val warnMessage: String =
                    getWarnMessage(
                        JAVA_NAME,
                        version.toString(),
                        warnJavaVersion.toString(),
                        POTENTIAL_JAVA_FIX
                    )
                project.logger.error(warnMessage)
            }
        }

        fun checkAGPVersion(
            version: Version,
            project: Project
        ) {
            if (version < errorAGPVersion) {
                val errorMessage: String =
                    getErrorMessage(
                        AGP_NAME,
                        version.toString(),
                        errorAGPVersion.toString(),
                        getPotentialAGPFix(project.getRootDir().getPath())
                    )
                project.extra.set(OUT_OF_SUPPORT_RANGE_PROPERTY, true)
                throw DependencyValidationException(errorMessage)
            } else if (version < warnAGPVersion) {
                val warnMessage: String =
                    getWarnMessage(
                        AGP_NAME,
                        version.toString(),
                        warnAGPVersion.toString(),
                        getPotentialAGPFix(project.getRootDir().getPath())
                    )
                project.logger.error(warnMessage)
            }
        }

        fun checkKGPVersion(
            version: Version,
            project: Project
        ) {
            if (version < errorKGPVersion) {
                val errorMessage: String =
                    getErrorMessage(
                        KGP_NAME,
                        version.toString(),
                        errorKGPVersion.toString(),
                        getPotentialKGPFix(project.getRootDir().getPath())
                    )
                project.extra.set(OUT_OF_SUPPORT_RANGE_PROPERTY, true)
                throw DependencyValidationException(errorMessage)
            } else if (version < warnKGPVersion) {
                val warnMessage: String =
                    getWarnMessage(
                        KGP_NAME,
                        version.toString(),
                        warnKGPVersion.toString(),
                        getPotentialKGPFix(project.getRootDir().getPath())
                    )
                project.logger.error(warnMessage)
            }
        }
    }
}

                                                                                             
                                                                                                 
                                                                        
                                                                                                  
class Version(val major: Int, val minor: Int, val patch: Int) : Comparable<Version> {
    companion object {
        fun fromString(version: String): Version {
            val asList: List<String> = version.split(".")
            val convertedToNumbers: List<Int> = asList.map { it.toIntOrNull() ?: 0 }
            return Version(
                major = convertedToNumbers.getOrElse(0, { 0 }),
                minor = convertedToNumbers.getOrElse(1, { 0 }),
                patch = convertedToNumbers.getOrElse(2, { 0 })
            )
        }
    }

    override fun compareTo(other: Version): Int {
        if (major != other.major) {
            return major - other.major
        }
        if (minor != other.minor) {
            return minor - other.minor
        }
        if (patch != other.patch) {
            return patch - other.patch
        }
        return 0
    }

    override fun toString(): String {
        return major.toString() + "." + minor.toString() + "." + patch.toString()
    }
}

                                                                                            
                             
class DependencyValidationException(message: String? = null, cause: Throwable? = null) : Exception(message, cause) {
    constructor(cause: Throwable) : this(null, cause)
}