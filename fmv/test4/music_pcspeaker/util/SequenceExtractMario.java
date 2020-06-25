
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import javax.sound.midi.MidiChannel;
import javax.sound.midi.MidiEvent;
import javax.sound.midi.MidiMessage;
import javax.sound.midi.MidiSystem;
import javax.sound.midi.Sequence;
import javax.sound.midi.ShortMessage;
import javax.sound.midi.Synthesizer;
import javax.sound.midi.Track;


/**
 *
 * @author leo
 */
public class SequenceExtractMario {

    public static void main(String[] args) throws Exception {
        List<Integer> notes = new ArrayList<>();
        
        Synthesizer synthesizer = MidiSystem.getSynthesizer();
        synthesizer.open();
        MidiChannel midiChannel = synthesizer.getChannels()[0];
        // Sequence sequence = MidiSystem.getSequence(SequenceTest.class.getResourceAsStream("moonlight_sonata.mid"));
        Sequence sequence = MidiSystem.getSequence(SequenceTest.class.getResourceAsStream("mario.mid"));
        //Sequence sequence = MidiSystem.getSequence(SequenceTest.class.getResourceAsStream("kingsv.mid"));
        
        //Sequencer sequencer = MidiSystem.getSequencer();
        //sequencer.setSequence(sequence);
        //sequencer.open();
        //sequencer.start();
        
        System.out.println("resolution: " + sequence.getResolution()); // como obter o tick / segundo ?
        
        Map<Long, List<MidiEvent>> events = new HashMap<Long, List<MidiEvent>>();
        
        int maxTracks = sequence.getTracks().length;
        maxTracks = 2;
        for (int t = 0; t < maxTracks; t++) {
            Track track = sequence.getTracks()[t];
            
            for (int i = 0; i < track.size(); i++) {
                MidiEvent me = track.get(i);
                Long tick = me.getTick();
                List<MidiEvent> list = events.get(tick);
                if (list == null) {
                    list = new ArrayList<MidiEvent>();
                    events.put(tick, list);
                }
                list.add(me);
            }
        }
        
        Long tick = 0l;
        while (tick  <= sequence.getTickLength()) {
            List<MidiEvent> list = events.get(tick);
            if (list != null) {
                for (MidiEvent me : list) {
                    MidiMessage midiMessage = me.getMessage();
                    
                    //System.out.print("midi event: status: " + midiMessage.getStatus() + " length: " + midiMessage.getLength() + " tick: "+ me.getTick() + " bytes: ");
                    //for (byte b : midiMessage.getMessage()) {
                    //    System.out.print((int) (b & 0xff) + " ");
                    //}
                    
                    switch (midiMessage.getStatus() & ShortMessage.NOTE_ON) {
                        case ShortMessage.NOTE_ON:
                            int note = (int) (midiMessage.getMessage()[1] & 0xff);
                            int velocity = (int) (midiMessage.getMessage()[2] & 0xff);
                            midiChannel.noteOn(note, velocity);
                            System.out.println("tick: "+ tick + " note_on: " + note);
                            notes.add(note);
                            break;
                        case ShortMessage.NOTE_OFF:
                            int note2 = (int) (midiMessage.getMessage()[1] & 0xff);
                            //int velocity2 = (int) (midiMessage.getMessage()[2] & d0xff);
                            midiChannel.noteOff(note2);
                            System.out.println("tick: "+ tick + " note_off: " + note2);
                            notes.add(254);
                            break;
                    }
                    System.out.println();
                }
            }
            else {
                // ignore
                notes.add(255);
            }
            //Thread.sleep(6);
            //System.out.println("----------------------");
            tick += 8;
        }
        
        
        System.out.println("music size: " + notes.size());
        for (int i = 0; i < notes.size(); i++) {
            int noteInt = notes.get(i);
            String noteStr = "00" + Integer.toHexString(noteInt);
            noteStr = noteStr.substring(noteStr.length() - 2, noteStr.length());
            noteStr = "0" + noteStr + "h";
            
            if (i % 16 == 0) {
                System.out.print("\r\n\tdb ");
            }

            System.out.print(noteStr + (i % 16 == 15 ? "" : ", "));
        }
    }
    
}
