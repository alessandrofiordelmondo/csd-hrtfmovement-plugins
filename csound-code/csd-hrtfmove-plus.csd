<Cabbage> 
form caption("csd-hrtfmove-plus") size(325, 360), colour(255, 255, 255), pluginid("def1")
label bounds(20, 5, 211, 18), channel("label2"), text("CSD - HRTFMOVE"), align("left"), fontcolour(0, 100, 120)
label bounds(172, 4, 48, 18), channel("label2"), text("PLUS"), align("left"), fontcolour(170, 170, 0, 255)
;Position

;PAD [azimuth plane]
xypad bounds(14, 28, 209, 240), channel("x", "y"), , , text("AZIMUTH"), colour(255, 255, 255, 255), , textcolour(0, 180, 200, 255), fontcolour(0, 0, 0, 0) ballcolour(0, 180, 200, 255) backgroundcolour(0, 180, 200, 34)  , rangex(0, 1, 0.5) rangey(0, 1, 0.5)
;vertical plane
rslider bounds(14, 272, 77, 83), range(0, 1, 0.5, 1, 0.001), channel("vertical"), text("VERITCAL"), , textcolour(0, 180, 200, 255), fontcolour(0, 180, 200, 255) trackercolour(0, 180, 200, 255)  textboxcolour(221, 221, 221, 248) textboxoutlinecolour(253, 252, 252, 255) colour(189, 255, 255, 0) trackerinsideradius(0.85) outlinecolour(85, 85, 85, 255)

;REVERB
;dry
rslider bounds(236, 4, 71, 115), range(0, 1, 1, 1, 0.001), channel("Dry"), text("DRY"), , textcolour(0, 180, 200, 255), fontcolour(0, 85, 85, 255) colour(255, 255, 255, 255)   outlinecolour(85, 85, 85, 255) trackercolour(0, 180, 200, 255) trackerinsideradius(0.85) 
;early
rslider bounds(236, 122, 73, 115), range(0, 1, 1, 1, 0.001), channel("Early"), text("EARLY"),  textcolour(0, 180, 200, 255), colour(255, 255, 255, 255), fontcolour(0, 85, 85, 255)  trackerinsideradius(0.85) outlinecolour(85, 85, 85, 255) trackercolour(0, 180, 200, 255) 
;late
rslider bounds(236, 238, 73, 115), range(0, 1, 1, 1, 0.001), channel("Late"), text("LATE"), colour(255, 255, 255, 255), textcolour(0, 180, 200, 255), fontcolour(0, 85, 85, 255) outlinecolour(85, 85, 85, 255) trackercolour(0, 180, 200, 255)  trackerinsideradius(0.85)

combobox bounds(108, 308, 106, 21), channel("samplerate"), items("44100Hz", "48000Hz", "96000Hz")

label bounds(108, 294, 106, 13) text("HRTF sample rate") fontcolour(0, 180, 200, 255) align("left")

label bounds(232, 208, 80, 16) text("reverb") fontcolour(170, 170, 0, 255)
label bounds(232, 322, 80, 16) text("reverb") fontcolour(170, 170, 0, 255)
</Cabbage>
<CsoundSynthesizer>
<CsOptions>
-d -n
</CsOptions>
<CsInstruments>
ksmps = 16 
nchnls = 2 
0dbfs = 1
;global variable
gksr = 44100
gSLeftHRTF[] fillarray "hrtf-44100-left.dat", "hrtf-48000-left.dat", "hrtf-96000-left.dat"
gSRightHRTF[] fillarray "hrtf-44100-right.dat", "hrtf-48000-right.dat", "hrtf-96000-right.dat"
gSLeft = "hrtf-44100-left.dat"
gSRight = "hrtf-44100-right.dat"
gki = 0
;pi
giPi = cosinv(-1)
;select impulse sample rate
instr 1
kSampleRate chnget "samplerate"
if kSampleRate == 1 then 
    gki = 0
    gksr = 44100
elseif kSampleRate == 2 then 
    gki = 1
    gksr = 48000
elseif kSampleRate == 3 then 
    gki = 2
    gksr = 96000
endif
gSLeft = gSLeftHRTF[gki]
gSRight = gSRightHRTF[gki]
ktrig changed gSLeft
if ktrig==1 then
    turnoff2 99, 1, 10
    event "i",99,0,3600*24*7
endif
endin
;binaural instrument
instr 99
isr = i(gksr)
;get input control channel
kX chnget "x"
kY chnget "y"
kV chnget "vertical"
kDry chnget "Dry"
kEarl chnget "Early"
kLate chnget "Late"
;smooth control
kX tonek kX, 1
kY tonek kY, 1
kV tonek kV, 1
kDry tonek kDry, 1
kEarl tonek kEarl, 1
kLate tonek kLate, 1
;audio input channels
aL, aR ins ;read stereo input
aMono = (aL + aR) * 0.5   ; sum to mono input
;calculate azimuth
kX2 = kX*2-1
kY2 = kY*2-1
kR = sqrt(kX2*kX2 + kY2*kY2)
kyY = kY2/kR
kxX = kX2/kR
ksin = sininv(kyY)
kcos = cosinv(kxX)
if ksin>=0 then 
    kalpha = (giPi/2)-kcos
    kc = 1111
elseif ksin<0 then
    if kcos>=(giPi/2) then
        kalpha = kcos-(3*giPi/2)
    else
        kalpha = kcos + (giPi/2)
    endif
endif
kAz = kalpha*180/giPi
;calculate elevation
if kV>=0.5 then
    kEl = (kV-0.5)*180
elseif kV<0.5 then
    kEl = (kV-0.5)*80
endif
;apply distance
ksX = kX * 20
ksY = kY * 25
ksV = kV * 7
;get distance for dry sound
kDryDist = 1-(kR*50/75)
;dry binaural
aDryL,aDryR hrtfmove aMono*kDryDist, kAz, kEl, gSLeft, gSRight
;early reflaction binaural
aEarlyL, aEarlyR, irt60low, irt60high, impf hrtfearly, aMono, ksX, ksY, ksV, 10, 12.5, 3.5, gSLeft, gSRight, 3
;later reverb binaural
aRevL, aRevR, idel hrtfreverb, aMono, irt60low, irt60high, gSLeft, gSRight, isr, impf
;deleyed and scaled
aLateL delay aRevL * .1, idel
aLateR delay aRevR * .1, idel 
;outputs
outs aDryL*kDry + aEarlyL*kEarl + aLateL*kLate, aDryR*kDry + aEarlyR*kEarl + aLateR*kLate
endin
</CsInstruments>
<CsScore>
i1 0 [3600*24*7]
i99 0 [60*60*24*7]
</CsScore>
</CsoundSynthesizer>