# Readable release stack traces (mapping file is produced by R8 and uploaded with the bundle).
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# kotlinx.serialization: kotlinx-serialization-core ships its own R8 rules; these additionally pin
# the app's @Serializable classes (including private nested DTOs in DashboardDataService and
# NominatimSearchService) so serializer lookups survive full-mode R8.
-keepattributes InnerClasses,Signature,RuntimeVisibleAnnotations,AnnotationDefault
-keepclassmembers @kotlinx.serialization.Serializable class org.entner.HitzeV.** {
    *** Companion;
    *** INSTANCE;
    kotlinx.serialization.KSerializer serializer(...);
}
-keepclassmembers class org.entner.HitzeV.**$Companion {
    kotlinx.serialization.KSerializer serializer(...);
}
-keep,includedescriptorclasses class org.entner.HitzeV.**$$serializer { *; }

# FirebaseMessagingService, WorkManager workers and the Application are referenced from the
# manifest / WorkManager's database; AAPT and the libraries' consumer rules keep them.
