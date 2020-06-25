package javamidinotefrequencyalgorithm;

/**
 *
 * @author leo
 */
public class JavaMidiNoteFrequencyAlgorithm {

    /**
     * @param args the command line arguments
     */
    public static void main(String[] args) {
        test2();
    }

    private static void test2() {
        //http://www.inspiredacoustics.com/en/MIDI_note_numbers_and_center_frequencies
        for (int noteNumber = 0; noteNumber < 128; noteNumber++) {
            double frequency = 440 * Math.pow(2, (noteNumber - 69) / 12.0);
            int frequencyInt = (int) (1193180 / frequency);
            
            String frequencyHex = "0000" + Integer.toHexString(frequencyInt);
            frequencyHex = frequencyHex.substring(frequencyHex.length() - 4, frequencyHex.length());
            
            if (noteNumber % 8 == 0) {
                System.out.print("\r\n\tdb ");
            }
            
            System.out.print("0" + frequencyHex.subSequence(2, 4) + "h, 0" + frequencyHex.substring(0, 2) + "h" + ((noteNumber % 8 != 7) ? ", " : ""));
        }
        
        System.out.println("");
    }
    
    private static void test() {
        //http://www.inspiredacoustics.com/en/MIDI_note_numbers_and_center_frequencies
        for (int noteNumber = 0; noteNumber < 128; noteNumber++) {
            double frequency = 440 * Math.pow(2, (noteNumber - 69) / 12.0);
            int frequencyInt = (int) frequency;
            
            // convert to adlib f_num
            int block = 6;
            double f_num = frequency * Math.pow(2, (20 - block)) / 49716;
            String f_num_hex = Integer.toHexString((int) f_num);
            
            System.out.println(noteNumber + " = " + Integer.toHexString(frequencyInt) + " ---> f_num_hex = " + f_num_hex);
        }
    }
    
}
