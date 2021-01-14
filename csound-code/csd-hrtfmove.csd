<Cabbage> 
form caption("csd-hrtfmove") size(400, 120), colour(255, 255, 255), pluginid("def1")
label bounds(20, 5, 300, 18), channel("label2"), text("CSD - HRTFMOVE"), align("left"), fontcolour(0, 100, 120)
rslider bounds(10, 30, 79, 74), channel("azimuth"), range(-180, 180, 0, 1, 1), text("azimuth"), trackercolour(0, 180, 200, 255), outlinecolour(85, 85, 85, 255), textcolour(0, 180, 200, 255) trackerinsideradius(0.85)
rslider bounds(96, 30, 80, 74), channel("elevation"), range(-40, 90, 0, 1, 1), text("elevation"), trackercolour(0, 180, 200, 255), outlinecolour(85, 85, 85, 255), textcolour(0, 180, 200, 255) trackerinsideradius(0.85)
rslider bounds(180, 30, 80, 75), channel("distance"), range(0, 100, 0, 1, 0.1), text("distance"), trackercolour(0, 180, 200, 255), outlinecolour(85, 85, 85, 255), textcolour(0, 180, 200, 255) trackerinsideradius(0.85)
combobox bounds(292, 60, 100, 20), channel("samplerate"), items("44100Hz", "48000Hz", "96000Hz")
label bounds(292, 28, 300, 18), channel("label1"), text("HRTF"), align("left"), fontcolour(0, 180, 200)
label bounds(292, 40, 300, 18), channel("label2"), text("sample rate"), align("left"), fontcolour(0, 180, 200)
</Cabbage>
<CsoundSynthesizer>
<CsOptions>
-d -n
</CsOptions>
<CsInstruments>
; Initialize the global variables. 
ksmps = 16 
nchnls = 2 
0dbfs = 1
;global variable
gSLeftHRTF[] fillarray "hrtf-44100-left.dat", "hrtf-48000-left.dat", "hrtf-96000-left.dat"
gSRightHRTF[] fillarray "hrtf-44100-right.dat", "hrtf-48000-right.dat", "hrtf-96000-right.dat"
gSLeft = "hrtf-44100-left.dat"
gSRight = "hrtf-44100-right.dat"
gki = 0
gkMaxDist = 100

instr 1

kSampleRate chnget "samplerate"

if kSampleRate == 1 then 
    gki = 0
elseif kSampleRate == 2 then 
    gki = 1
elseif kSampleRate == 3 then 
    gki = 2
endif

gSLeft = gSLeftHRTF[gki]
gSRight = gSRightHRTF[gki]

ktrig changed gSLeft
if ktrig==1 then
    turnoff2 99, 1, 10
    event "i",99,0,3600*24*7
endif
endin

instr 99
kmax = 100

kAz chnget "azimuth"
kEl chnget "elevation"
kDi chnget "distance"

kAz tonek kAz, 1
kEl tonek kEl, 1
kDi tonek kDi, 1

kDistance = 1- (kDi/kmax)

a1, a2 ins
aInput = (a1+a2)*0.5

aleft,aright hrtfmove aInput, kAz, kEl, gSLeft, gSRight

outs aleft*kDistance, aright*kDistance

endin


</CsInstruments>
<CsScore>
i1 0 [60*60*24*7]
i99 0 [60*60*24*7]
</CsScore>
</CsoundSynthesizer>
