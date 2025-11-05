import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.jar.JarEntry;
import java.util.jar.JarInputStream;
import java.util.jar.JarOutputStream;

public class JarMerger {
    private static final Map<String, Boolean> entryMap = new HashMap<>();

    public static void merge(String jarFile1, String jarFile2, String outputJar) {
        try (FileOutputStream fos = new FileOutputStream(outputJar);
             JarOutputStream jos = new JarOutputStream(fos)) {

            addEntries(jarFile1, jos);
            addEntries(jarFile2, jos);

        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    private static void addEntries(String jarFile, JarOutputStream jos) throws IOException {
        try (FileInputStream fis = new FileInputStream(jarFile);
             JarInputStream jis = new JarInputStream(fis)) {

            JarEntry entry;
            byte[] buffer = new byte[4096];

            while ((entry = jis.getNextJarEntry()) != null) {
                String entryName = entry.getName();

                if (entryMap.getOrDefault(entryName, false)) {
                    continue;
                }

                JarEntry newEntry = new JarEntry(entryName);
                jos.putNextEntry(newEntry);

                int bytesRead;
                while ((bytesRead = jis.read(buffer)) != -1) {
                    jos.write(buffer, 0, bytesRead);
                }

                entryMap.put(entryName, true);
                jos.closeEntry();
            }
        }
    }

    public static void main(String[] args) {
        if (args.length != 3) {
            System.out.println("Usage: java JarMerger <jar1> <jar2> <output.jar>");
            return;
        }

        String jarFile1 = args[0];
        String jarFile2 = args[1];
        String outputJar = args[2];

        merge(jarFile1, jarFile2, outputJar);
        System.out.println("Merge completed: " + outputJar);
    }
}
