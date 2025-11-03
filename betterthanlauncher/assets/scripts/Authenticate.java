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

    /**
     * Logs in using Microsoft Device Code flow and returns the full session/profile JSON.
     */
    public static JsonObject loginAndGetProfileJson() {
        try {
            HttpClient httpClient = MinecraftAuth.createHttpClient();

            // Use the built-in login flow for Java Edition device code.
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

            // Serialize the session (which contains token chain + profile info) to JSON
            JsonObject serialized = MinecraftAuth.JAVA_DEVICE_CODE_LOGIN.toJson(javaSession);
            return serialized;
        } catch (Exception e) {
            System.err.println("Login failed: " + e.getMessage());
            e.printStackTrace();
            return null;
        }
    }

    /**
     * Validates a session/profile JSON string (serialized from a previous login).
     * Returns true if the session is still valid (i.e., can refresh / contains MC token).
     */
    public static boolean validateProfileJson(String sessionJsonString) {
        try {
            JsonObject json = GSON.fromJson(sessionJsonString, JsonObject.class);
            StepFullJavaSession.FullJavaSession session =
                MinecraftAuth.JAVA_DEVICE_CODE_LOGIN.fromJson(json);

            // Attempt to refresh (this will throw if invalid/expired)
            session = MinecraftAuth.JAVA_DEVICE_CODE_LOGIN.refresh(MinecraftAuth.createHttpClient(), session);

            // Now check that the MC profile inside is non‐null and has an MC token
            if (session.getMcProfile() != null && session.getMcProfile().getMcToken() != null) {
                return true;
            }
            return false;
        } catch (Exception e) {
            System.err.println("Validation failed: " + e.getMessage());
            //e.printStackTrace();
            return false;
        }
    }

    public static void main(String[] args) {
        if (args.length > 0) {
            // The first argument is assumed to be a session/profile JSON string
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
