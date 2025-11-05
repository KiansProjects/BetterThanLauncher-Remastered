import com.google.gson.Gson;
import com.google.gson.JsonObject;
import net.raphimc.minecraftauth.MinecraftAuth;
import net.raphimc.minecraftauth.step.java.session.StepFullJavaSession;
import net.raphimc.minecraftauth.step.msa.StepMsaDeviceCode;
import net.lenni0451.commons.httpclient.HttpClient;

import java.awt.Desktop;
import java.net.URI;

public class Authenticate {
    private static final Gson GSON = new Gson();

    public static JsonObject loginAndGetProfileJson() {
        try {
            HttpClient httpClient = MinecraftAuth.createHttpClient();

            StepFullJavaSession.FullJavaSession javaSession =
                MinecraftAuth.JAVA_DEVICE_CODE_LOGIN.getFromInput(
                    httpClient,
                    new StepMsaDeviceCode.MsaDeviceCodeCallback(deviceCode -> {
                        try {
                            if (Desktop.isDesktopSupported()) {
                                Desktop.getDesktop().browse(new URI(deviceCode.getDirectVerificationUri()));
                            } else {
                                System.out.println("Automatic browser opening is not supported on this platform.");
                            }
                        } catch (Exception e) {
                            System.err.println("Failed to open browser: " + e.getMessage());
                        }
                    })
                );

            JsonObject serialized = MinecraftAuth.JAVA_DEVICE_CODE_LOGIN.toJson(javaSession);
            return serialized;
        } catch (Exception e) {
            System.err.println("Login failed: " + e.getMessage());
            e.printStackTrace();
            return null;
        }
    }

    public static boolean validateProfileJson(String sessionJsonString) {
        try {
            JsonObject json = GSON.fromJson(sessionJsonString, JsonObject.class);
            StepFullJavaSession.FullJavaSession session =
                MinecraftAuth.JAVA_DEVICE_CODE_LOGIN.fromJson(json);

            session = MinecraftAuth.JAVA_DEVICE_CODE_LOGIN.refresh(MinecraftAuth.createHttpClient(), session);

            if (session.getMcProfile() != null && session.getMcProfile().getMcToken() != null) {
                return true;
            }
            return false;
        } catch (Exception e) {
            System.err.println("Validation failed: " + e.getMessage());
            return false;
        }
    }

    public static void main(String[] args) {
        if (args.length > 0) {
            String sessionJson = args[0];
            boolean valid = validateProfileJson(sessionJson);
            if (valid) {
                System.out.println("Profile/session is valid");
            } else {
                System.out.println("Profile/session is invalid or expired");
            }
        } else {
            JsonObject sessionJson = loginAndGetProfileJson();
            if (sessionJson != null) {
                System.out.println(GSON.toJson(sessionJson));
            } else {
                System.out.println("Login error occurred");
            }
        }
    }
}
