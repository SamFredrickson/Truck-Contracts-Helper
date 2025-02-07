local Sound = {
    new = function(name, volume)
        local self = {}
        self.workingDirectory = getWorkingDirectory()
        self.volume = volume
        self.audioStream = loadAudioStream
        (
            string.format
            (
                "%s/tch/resources/%s",
                self.workingDirectory,
                name
            )
        )
        setAudioStreamVolume(self.audioStream, self.volume)
        return self
    end
}

return Sound