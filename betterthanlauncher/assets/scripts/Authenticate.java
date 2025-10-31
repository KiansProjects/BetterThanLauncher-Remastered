import net.lenni0451.commons.httpclient.HttpClient;
import net.raphimc.minecraftauth.MinecraftAuth;
import net.raphimc.minecraftauth.step.java.session.StepFullJavaSession;
import net.raphimc.minecraftauth.step.msa.StepMsaDeviceCode;

import java.awt.Desktop;
import java.net.URI;

public class Authenticate {

    /**
     * Logs in using Microsoft Device Code flow (supports 2FA).
     * Automatically opens the verification URL in the default browser.
     *
     * @return Minecraft access token or null if login fails
     */
    public static String loginAndGetToken() {
        try {
            HttpClient httpClient = MinecraftAuth.createHttpClient();

            // Device‑code login flow
            StepFullJavaSession.FullJavaSession javaSession = MinecraftAuth.JAVA_DEVICE_CODE_LOGIN.getFromInput(
                    httpClient,
                    new StepMsaDeviceCode.MsaDeviceCodeCallback(msaDeviceCode -> {
                        System.out.println("Open this URL in your browser: " + msaDeviceCode.getVerificationUri());
                        System.out.println("Enter the code: " + msaDeviceCode.getUserCode());
                        System.out.println("Direct URL (optional): " + msaDeviceCode.getDirectVerificationUri());

                        // Attempt to open in browser
                        try {
                            if (Desktop.isDesktopSupported()) {
                                Desktop.getDesktop().browse(new URI(msaDeviceCode.getDirectVerificationUri()));
                            } else {
                                System.out.println("Automatic browser opening not supported on this platform.");
                            }
                        } catch (Exception e) {
                            System.err.println("Failed to open browser: " + e.getMessage());
                        }
                    })
            );

            String accessToken = javaSession.getMcProfile().getMcToken().getAccessToken();
            System.out.println("Login successful! Username: " + javaSession.getMcProfile().getName());
            System.out.println("Access token: " + accessToken);

            return accessToken;

        } catch (Exception e) {
            System.err.println("Device code login failed: " + e.getMessage());
            e.printStackTrace();
            return null;
        }
    }

    public static void main(String[] args) {
        String token = loginAndGetToken();
        if (token != null) {
            System.out.println("Access Token for Flutter: " + token);
        } else {
            System.out.println("Login failed.");
        }
    }
}
