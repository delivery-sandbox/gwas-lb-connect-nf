import java.nio.file.NoSuchFileException
import java.io.FileNotFoundException

def step_check(nf_channel) {
    try {
        return nf_channel
    } catch (NoSuchFileException | FileNotFoundException ignored) {
        return false
    }
}

def file_check(nf_channel, alt_input) {
    try {
        return nf_channel
    } catch (NoSuchFileException | FileNotFoundException ignored) {
        return Channel.fromPath("$alt_input")
    }
}
