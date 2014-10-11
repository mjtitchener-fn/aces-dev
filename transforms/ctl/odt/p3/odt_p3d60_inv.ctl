// 
// Inverse P3D60 ODT
// WGR8
//



import "utilities";
import "transforms-common";
import "odt-transforms-common";



/* --- ODT Parameters --- */
const Chromaticities DISPLAY_PRI = P3D60_PRI;
const float DISPLAY_PRI_2_XYZ_MAT[4][4] = RGBtoXYZ( DISPLAY_PRI, 1.0);

const float DISPGAMMA = 2.6; 

const float ODT_COEFS[6] = { 
	0.37358,
	0.98891,
	1.44330,
	1.60290,
	1.66893,
	1.69355
};



void main 
(
  input varying float rIn, 
  input varying float gIn, 
  input varying float bIn, 
  input varying float aIn,
  output varying float rOut,
  output varying float gOut,
  output varying float bOut,
  output varying float aOut
)
{
  // --- Initialize a 3-element vector with input variables (0-1 CV) --- //
    float outputCV[3] = { rIn, gIn, bIn};

  // --- Decode to linear code values with inverse transfer function --- //
    float linearCV[3];
    linearCV[0] = pow( outputCV[0], DISPGAMMA);
    linearCV[1] = pow( outputCV[1], DISPGAMMA);
    linearCV[2] = pow( outputCV[2], DISPGAMMA);

  // --- Convert from display primary encoding --- //
    // Display primaries to CIE XYZ
    float XYZ[3] = mult_f3_f44( linearCV, DISPLAY_PRI_2_XYZ_MAT);
  
    // CIE XYZ to OCES RGB
    linearCV = mult_f3_f44( XYZ, XYZ_2_ACES_MAT);
  
  // --- Apply inverse black point compensation --- //
    float rgbPre[3] = bpc_cinema_inv( linearCV);
  
  // --- Apply the tonescale independently in rendering-space RGB --- //
    // OCES to RGB rendering space
    rgbPre = mult_f3_f44( rgbPre, ACES_2_RENDER_PRI_MAT);

    // Tonescale
    float rgbPost[3];
    rgbPost[0] = odt_tonescale_rev( rgbPre[0], ODT_COEFS);
    rgbPost[1] = odt_tonescale_rev( rgbPre[1], ODT_COEFS);
    rgbPost[2] = odt_tonescale_rev( rgbPre[2], ODT_COEFS);

    // RGB rendering space back to OCES encoding
    float oces[3] = mult_f3_f44( rgbPost, RENDER_PRI_2_ACES_MAT);
    
  // --- Cast OCES to rOut, gOut, bOut --- //
    rOut = oces[0];
    gOut = oces[1];
    bOut = oces[2];
    aOut = aIn;
}