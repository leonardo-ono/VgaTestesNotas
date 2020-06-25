
import java.io.FileNotFoundException;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;
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
        Sequence sequence = MidiSystem.getSequence(SequenceExtractMario.class.getResourceAsStream("badapple.mid"));
        //Sequence sequence = MidiSystem.getSequence(SequenceTest.class.getResourceAsStream("kingsv.mid"));
        
        //Sequencer sequencer = MidiSystem.getSequencer();
        //sequencer.setSequence(sequence);
        //sequencer.open();
        //sequencer.start();
        
        System.out.println("resolution: " + sequence.getResolution()); // como obter o tick / segundo ?
        
        Map<Long, List<MidiEvent>> events = new HashMap<Long, List<MidiEvent>>();
        
        int maxTracks = sequence.getTracks().length;
        
        //maxTracks = 5;
        
        for (int t = 0; t < maxTracks; t++) {
            if (t==1 || t==3) {
                Track track = sequence.getTracks()[t];

                for (int i = 0; i < track.size(); i++) {
                    MidiEvent me = track.get(i);
                    Long tick = me.getTick();
                    List<MidiEvent> list = events.get(tick);
                    if (list == null) {
                        list = new ArrayList<MidiEvent>();
                        if (t==1){
                            events.put(tick + 8, list);
                        }
                        //if (t==2){
                        //    events.put(tick + 8, list);
                        //}
                        else {
                            events.put(tick, list);
                        }
                    }
                    list.add(me);
                }
            }
        }
        
        int notesSize = 0;
        
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
                            notesSize++;
                            break;
                        case ShortMessage.NOTE_OFF:
                            //if (1 == 1) {
                            //    notes.add(255);
                            //    break;
                            //} // <-- test
                            
                            int note2 = (int) (midiMessage.getMessage()[1] & 0xff);
                            //int velocity2 = (int) (midiMessage.getMessage()[2] & d0xff);
                            midiChannel.noteOff(note2);
                            System.out.println("tick: "+ tick + " note_off: " + note2);
                            notes.add(254);
                            notesSize++;
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
        
        
        System.out.println("notes size: " + notesSize);
        
        System.out.println("music size: " + notes.size());

        print("mario_music_size dw " + notes.size() + "\n\n");

        print("; 0~127 -> midi note\n");
        print("; 254   -> note off\n");
        print("; 255   -> ignore\n");
        print("mario_music:\n");
        
        for (int i = 0; i < notes.size(); i++) {
            int noteInt = notes.get(i);
            String noteStr = "00" + Integer.toHexString(noteInt);
            noteStr = noteStr.substring(noteStr.length() - 2, noteStr.length());
            noteStr = "0" + noteStr + "h";
            
            if (i % 16 == 0) {
                print("\r\n\tdb ");
            }

            print(noteStr + (i % 16 == 15 ? "" : ", "));
        }
        
        closeFile();
    }
    
    private static PrintWriter pw;
    
    static {
        try {
            pw = new PrintWriter("D:/vga/fmv/test4/music_pcspeaker/music.dat");
        } catch (FileNotFoundException ex) {
            Logger.getLogger(SequenceExtractMario.class.getName()).log(Level.SEVERE, null, ex);
            System.exit(-1);
        }
    }
    
    private static void print(String data) {
        pw.print(data);
    }
    
    
    private static void closeFile() {
        pw.close();
    }
    
}
