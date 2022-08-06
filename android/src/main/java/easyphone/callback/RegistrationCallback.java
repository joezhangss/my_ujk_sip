package easyphone.callback;

/**
 *  2017/9/21.
 * 
 */

public abstract class RegistrationCallback {
    public void registrationNone() {}

    public void registrationProgress() {}

    public void registrationOk() {}

    public void registrationCleared() {}

    public void registrationFailed() {}
}
