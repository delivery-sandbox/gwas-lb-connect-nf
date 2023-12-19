import java.nio.file.NoSuchFileException
import java.io.FileNotFoundException

def step_check(nf_channel) {
    try {
        checked_file = nf_channel.flatMap { env -> file(env) }
        return nf_channel
    } catch (NoSuchFileException | FileNotFoundException ignored) {
        return false
    }
}

def file_check(nf_channel, alt_input) {
    try {
        checked_file = nf_channel.flatMap { env -> file(env) }
        return nf_channel
    } catch (NoSuchFileException | FileNotFoundException ignored) {
        return Channel.fromPath("$alt_input")
    }
}
