%%%%%%%%%%%%%%%%
define lines_fit(bin_lo, bin_hi, par)
%%%%%%%%%%%%%%%%
%!%+
%\function{lines}
%\synopsis{model for gaussian line profiles of highly ionized ions' transitions}
%\usage{fit_fun("lines(id)");}
%\description
%     The return values are the bin-averages of  1 + sum_i gauss_i(lambda) ,
%     i.e., lines is a multiplicative model.
%\seealso{gauss, set_lines_par_fun}
%!%-
{
  variable i, g = 0*bin_lo;
  for(i=0; i<199; i++)
  { variable EW = par[4*i+1]/1e3;
    if(EW!=0) %                                  gauss.sigma = FWHM / (2*sqrt{2*ln(2)})
    { g += eval_fun2("gauss", bin_lo, bin_hi, [EW, par[4*i], par[4*i+2]*0.0004246609]); }
  }
  return 1. + g/(bin_hi-bin_lo);
}

%%%%%%%%%%%%%%%%%%%%%
define lines_defaults(i)
%%%%%%%%%%%%%%%%%%%%%
{
  switch(i)
% O8a (O VIII alpha)
  { case 0: return (18.9689, 1, 18.9057, 19.0321); }
  { case 1: return (0, 1, -100, 0); }
  { case 2: return (10, 1, 5, 76); }
  { case 3: return (0, 1, -1, 10); }
% O8b (O VIII beta)
  { case 4: return (16.0059, 1, 15.9525, 16.0593); }
  { case 5: return (0, 1, -100, 0); }
  { case 6: return (10, 1, 5, 64); }
  { case 7: return (0, 1, -1, 10); }
% O8g (O VIII gamma)
  { case 8: return (15.1762, 1, 15.1256, 15.2268); }
  { case 9: return (0, 1, -100, 0); }
  { case 10: return (10, 1, 5, 61); }
  { case 11: return (0, 1, -1, 10); }
% O8d (O VIII delta)
  { case 12: return (14.8206, 1, 14.7712, 14.8700); }
  { case 13: return (0, 1, -100, 0); }
  { case 14: return (10, 1, 5, 59); }
  { case 15: return (0, 1, -1, 10); }
% O7f (O VII f)
  { case 16: return (22.0977, 1, 22.0241, 22.1714); }
  { case 17: return (0, 1, -100, 0); }
  { case 18: return (10, 1, 5, 88); }
  { case 19: return (0, 1, -1, 10); }
% O7i (O VII i)
  { case 20: return (21.8036, 1, 21.7310, 21.8763); }
  { case 21: return (0, 1, -100, 0); }
  { case 22: return (10, 1, 5, 87); }
  { case 23: return (0, 1, -1, 10); }
% O7a (O VII alpha)
  { case 24: return (21.6015, 1, 21.5295, 21.6735); }
  { case 25: return (0, 1, -100, 0); }
  { case 26: return (10, 1, 5, 86); }
  { case 27: return (0, 1, -1, 10); }
% O7b (O VII beta)
  { case 28: return (18.6270, 1, 18.5649, 18.6891); }
  { case 29: return (0, 1, -100, 0); }
  { case 30: return (10, 1, 5, 75); }
  { case 31: return (0, 1, -1, 10); }
% O7g (O VII gamma)
  { case 32: return (17.7680, 1, 17.7088, 17.8272); }
  { case 33: return (0, 1, -100, 0); }
  { case 34: return (10, 1, 5, 71); }
  { case 35: return (0, 1, -1, 10); }
% O7d (O VII delta)
  { case 36: return (17.3960, 1, 17.3380, 17.4540); }
  { case 37: return (0, 1, -100, 0); }
  { case 38: return (10, 1, 5, 70); }
  { case 39: return (0, 1, -1, 10); }
% Ne10a (Ne X alpha)
  { case 40: return (12.1339, 1, 12.0934, 12.1743); }
  { case 41: return (0, 1, -100, 0); }
  { case 42: return (10, 1, 5, 49); }
  { case 43: return (0, 1, -1, 10); }
% Ne10b (Ne X beta)
  { case 44: return (10.2389, 1, 10.2047, 10.2730); }
  { case 45: return (0, 1, -100, 0); }
  { case 46: return (10, 1, 5, 41); }
  { case 47: return (0, 1, -1, 10); }
% Ne10g (Ne X gamma)
  { case 48: return (9.7082, 1, 9.6758, 9.7405); }
  { case 49: return (0, 1, -100, 0); }
  { case 50: return (10, 1, 5, 39); }
  { case 51: return (0, 1, -1, 10); }
% Ne10d (Ne X delta)
  { case 52: return (9.4807, 1, 9.4491, 9.5123); }
  { case 53: return (0, 1, -100, 0); }
  { case 54: return (10, 1, 5, 38); }
  { case 55: return (0, 1, -1, 10); }
% Ne10e (Ne X epsilon)
  { case 56: return (9.3616, 1, 9.3304, 9.3928); }
  { case 57: return (0, 1, -100, 0); }
  { case 58: return (10, 1, 5, 37); }
  { case 59: return (0, 1, -1, 10); }
% Ne10z (Ne X zeta)
  { case 60: return (9.2912, 1, 9.2603, 9.3222); }
  { case 61: return (0, 1, -100, 0); }
  { case 62: return (10, 1, 5, 37); }
  { case 63: return (0, 1, -1, 10); }
% Ne9f (Ne IX f)
  { case 64: return (13.6990, 1, 13.6533, 13.7446); }
  { case 65: return (0, 1, -100, 0); }
  { case 66: return (10, 1, 5, 55); }
  { case 67: return (0, 1, -1, 10); }
% Ne9i (Ne IX i)
  { case 68: return (13.5531, 1, 13.5079, 13.5983); }
  { case 69: return (0, 1, -100, 0); }
  { case 70: return (10, 1, 5, 54); }
  { case 71: return (0, 1, -1, 10); }
% Ne9a (Ne IX alpha)
  { case 72: return (13.4473, 1, 13.4025, 13.4921); }
  { case 73: return (0, 1, -100, 0); }
  { case 74: return (10, 1, 5, 54); }
  { case 75: return (0, 1, -1, 10); }
% Ne9b (Ne IX beta)
  { case 76: return (11.5440, 1, 11.5055, 11.5825); }
  { case 77: return (0, 1, -100, 0); }
  { case 78: return (10, 1, 5, 46); }
  { case 79: return (0, 1, -1, 10); }
% Ne9g (Ne IX gamma)
  { case 80: return (11.0010, 1, 10.9643, 11.0377); }
  { case 81: return (0, 1, -100, 0); }
  { case 82: return (10, 1, 5, 44); }
  { case 83: return (0, 1, -1, 10); }
% Ne9d (Ne IX delta)
  { case 84: return (10.7650, 1, 10.7291, 10.8009); }
  { case 85: return (0, 1, -100, 0); }
  { case 86: return (10, 1, 5, 43); }
  { case 87: return (0, 1, -1, 10); }
% Ne9e (Ne IX epsilon)
  { case 88: return (10.6426, 1, 10.6071, 10.6781); }
  { case 89: return (0, 1, -100, 0); }
  { case 90: return (10, 1, 5, 43); }
  { case 91: return (0, 1, -1, 10); }
% Ne9z (Ne IX zeta)
  { case 92: return (10.5650, 1, 10.5298, 10.6002); }
  { case 93: return (0, 1, -100, 0); }
  { case 94: return (10, 1, 5, 42); }
  { case 95: return (0, 1, -1, 10); }
% Na11a (Na XI alpha)
  { case 96: return (10.0250, 1, 9.9916, 10.0584); }
  { case 97: return (0, 1, -100, 0); }
  { case 98: return (10, 1, 5, 40); }
  { case 99: return (0, 1, -1, 10); }
% Na11b (Na XI beta)
  { case 100: return (8.4595, 1, 8.4313, 8.4877); }
  { case 101: return (0, 1, -100, 0); }
  { case 102: return (10, 1, 5, 34); }
  { case 103: return (0, 1, -1, 10); }
% Na11g (Na XI gamma)
  { case 104: return (8.0211, 1, 7.9943, 8.0478); }
  { case 105: return (0, 1, -100, 0); }
  { case 106: return (10, 1, 5, 32); }
  { case 107: return (0, 1, -1, 10); }
% Na11d (Na XI delta)
  { case 108: return (7.8332, 1, 7.8071, 7.8593); }
  { case 109: return (0, 1, -100, 0); }
  { case 110: return (10, 1, 5, 31); }
  { case 111: return (0, 1, -1, 10); }
% Na10f (Na X f)
  { case 112: return (11.1900, 1, 11.1527, 11.2273); }
  { case 113: return (0, 1, -100, 0); }
  { case 114: return (10, 1, 5, 45); }
  { case 115: return (0, 1, -1, 10); }
% Na10i (Na X i)
  { case 116: return (11.0800, 1, 11.0431, 11.1169); }
  { case 117: return (0, 1, -100, 0); }
  { case 118: return (10, 1, 5, 44); }
  { case 119: return (0, 1, -1, 10); }
% Na10a (Na X alpha)
  { case 120: return (11.0027, 1, 10.9660, 11.0394); }
  { case 121: return (0, 1, -100, 0); }
  { case 122: return (10, 1, 5, 44); }
  { case 123: return (0, 1, -1, 10); }
% Na10b (Na X beta)
  { case 124: return (9.4330, 1, 9.4016, 9.4644); }
  { case 125: return (0, 1, -100, 0); }
  { case 126: return (10, 1, 5, 38); }
  { case 127: return (0, 1, -1, 10); }
% Na10g (Na X gamma)
  { case 128: return (8.9828, 1, 8.9529, 9.0127); }
  { case 129: return (0, 1, -100, 0); }
  { case 130: return (10, 1, 5, 36); }
  { case 131: return (0, 1, -1, 10); }
% Na10d (Na X delta)
  { case 132: return (8.7884, 1, 8.7591, 8.8177); }
  { case 133: return (0, 1, -100, 0); }
  { case 134: return (10, 1, 5, 35); }
  { case 135: return (0, 1, -1, 10); }
% Mg12a (Mg XII alpha)
  { case 136: return (8.4210, 1, 8.3929, 8.4491); }
  { case 137: return (0, 1, -100, 0); }
  { case 138: return (10, 1, 5, 34); }
  { case 139: return (0, 1, -1, 10); }
% Mg12b (Mg XII beta)
  { case 140: return (7.1062, 1, 7.0825, 7.1298); }
  { case 141: return (0, 1, -100, 0); }
  { case 142: return (10, 1, 5, 28); }
  { case 143: return (0, 1, -1, 10); }
% Mg12g (Mg XII gamma)
  { case 144: return (6.7379, 1, 6.7154, 6.7604); }
  { case 145: return (0, 1, -100, 0); }
  { case 146: return (10, 1, 5, 27); }
  { case 147: return (0, 1, -1, 10); }
% Mg12d (Mg XII delta)
  { case 148: return (6.5801, 1, 6.5582, 6.6020); }
  { case 149: return (0, 1, -100, 0); }
  { case 150: return (10, 1, 5, 26); }
  { case 151: return (0, 1, -1, 10); }
% Mg11f (Mg XI f)
  { case 152: return (9.3143, 1, 9.2833, 9.3454); }
  { case 153: return (0, 1, -100, 0); }
  { case 154: return (10, 1, 5, 37); }
  { case 155: return (0, 1, -1, 10); }
% Mg11i (Mg XI i)
  { case 156: return (9.2312, 1, 9.2004, 9.2620); }
  { case 157: return (0, 1, -100, 0); }
  { case 158: return (10, 1, 5, 37); }
  { case 159: return (0, 1, -1, 10); }
% Mg11a (Mg XI alpha)
  { case 160: return (9.1687, 1, 9.1382, 9.1993); }
  { case 161: return (0, 1, -100, 0); }
  { case 162: return (10, 1, 5, 37); }
  { case 163: return (0, 1, -1, 10); }
% Mg11b (Mg XI beta)
  { case 164: return (7.8503, 1, 7.8241, 7.8765); }
  { case 165: return (0, 1, -100, 0); }
  { case 166: return (10, 1, 5, 31); }
  { case 167: return (0, 1, -1, 10); }
% Mg11g (Mg XI gamma)
  { case 168: return (7.4730, 1, 7.4481, 7.4979); }
  { case 169: return (0, 1, -100, 0); }
  { case 170: return (10, 1, 5, 30); }
  { case 171: return (0, 1, -1, 10); }
% Mg11d (Mg XI delta)
  { case 172: return (7.3101, 1, 7.2857, 7.3345); }
  { case 173: return (0, 1, -100, 0); }
  { case 174: return (10, 1, 5, 29); }
  { case 175: return (0, 1, -1, 10); }
% Al13a (Al XIII alpha)
  { case 176: return (7.1728, 1, 7.1489, 7.1967); }
  { case 177: return (0, 1, -100, 0); }
  { case 178: return (10, 1, 5, 29); }
  { case 179: return (0, 1, -1, 10); }
% Al13b (Al XIII beta)
  { case 180: return (6.0530, 1, 6.0328, 6.0731); }
  { case 181: return (0, 1, -100, 0); }
  { case 182: return (10, 1, 5, 24); }
  { case 183: return (0, 1, -1, 10); }
% Al13g (Al XIII gamma)
  { case 184: return (5.7393, 1, 5.7202, 5.7585); }
  { case 185: return (0, 1, -100, 0); }
  { case 186: return (10, 1, 5, 23); }
  { case 187: return (0, 1, -1, 10); }
% Al13d (Al XIII delta)
  { case 188: return (5.6049, 1, 5.5862, 5.6235); }
  { case 189: return (0, 1, -100, 0); }
  { case 190: return (10, 1, 5, 22); }
  { case 191: return (0, 1, -1, 10); }
% Al12f (Al XII f)
  { case 192: return (7.8721, 1, 7.8459, 7.8984); }
  { case 193: return (0, 1, -100, 0); }
  { case 194: return (10, 1, 5, 31); }
  { case 195: return (0, 1, -1, 10); }
% Al12i (Al XII i)
  { case 196: return (7.8070, 1, 7.7809, 7.8330); }
  { case 197: return (0, 1, -100, 0); }
  { case 198: return (10, 1, 5, 31); }
  { case 199: return (0, 1, -1, 10); }
% Al12a (Al XII alpha)
  { case 200: return (7.7573, 1, 7.7314, 7.7832); }
  { case 201: return (0, 1, -100, 0); }
  { case 202: return (10, 1, 5, 31); }
  { case 203: return (0, 1, -1, 10); }
% Al12b (Al XII beta)
  { case 204: return (6.6350, 1, 6.6129, 6.6571); }
  { case 205: return (0, 1, -100, 0); }
  { case 206: return (10, 1, 5, 27); }
  { case 207: return (0, 1, -1, 10); }
% Al12g (Al XII gamma)
  { case 208: return (6.3140, 1, 6.2930, 6.3350); }
  { case 209: return (0, 1, -100, 0); }
  { case 210: return (10, 1, 5, 25); }
  { case 211: return (0, 1, -1, 10); }
% Al12d (Al XII delta)
  { case 212: return (6.1750, 1, 6.1544, 6.1956); }
  { case 213: return (0, 1, -100, 0); }
  { case 214: return (10, 1, 5, 25); }
  { case 215: return (0, 1, -1, 10); }
% Si14a (Si XIV alpha)
  { case 216: return (6.1822, 1, 6.1616, 6.2028); }
  { case 217: return (0, 1, -100, 0); }
  { case 218: return (10, 1, 5, 25); }
  { case 219: return (0, 1, -1, 10); }
% Si14b (Si XIV beta)
  { case 220: return (5.2172, 1, 5.1998, 5.2346); }
  { case 221: return (0, 1, -100, 0); }
  { case 222: return (10, 1, 5, 21); }
  { case 223: return (0, 1, -1, 10); }
% Si14g (Si XIV gamma)
  { case 224: return (4.9469, 1, 4.9304, 4.9634); }
  { case 225: return (0, 1, -100, 0); }
  { case 226: return (10, 1, 5, 20); }
  { case 227: return (0, 1, -1, 10); }
% Si14d (Si XIV delta)
  { case 228: return (4.8311, 1, 4.8150, 4.8472); }
  { case 229: return (0, 1, -100, 0); }
  { case 230: return (10, 1, 5, 19); }
  { case 231: return (0, 1, -1, 10); }
% Si13f (Si XIII f)
  { case 232: return (6.7403, 1, 6.7178, 6.7628); }
  { case 233: return (0, 1, -100, 0); }
  { case 234: return (10, 1, 5, 27); }
  { case 235: return (0, 1, -1, 10); }
% Si13i (Si XIII i)
  { case 236: return (6.6882, 1, 6.6659, 6.7105); }
  { case 237: return (0, 1, -100, 0); }
  { case 238: return (10, 1, 5, 27); }
  { case 239: return (0, 1, -1, 10); }
% Si13a (Si XIII alpha)
  { case 240: return (6.6479, 1, 6.6258, 6.6701); }
  { case 241: return (0, 1, -100, 0); }
  { case 242: return (10, 1, 5, 27); }
  { case 243: return (0, 1, -1, 10); }
% Si13b (Si XIII beta)
  { case 244: return (5.6805, 1, 5.6616, 5.6994); }
  { case 245: return (0, 1, -100, 0); }
  { case 246: return (10, 1, 5, 23); }
  { case 247: return (0, 1, -1, 10); }
% Si13g (Si XIII gamma)
  { case 248: return (5.4045, 1, 5.3865, 5.4225); }
  { case 249: return (0, 1, -100, 0); }
  { case 250: return (10, 1, 5, 22); }
  { case 251: return (0, 1, -1, 10); }
% Si13d (Si XIII delta)
  { case 252: return (5.2850, 1, 5.2674, 5.3026); }
  { case 253: return (0, 1, -100, 0); }
  { case 254: return (10, 1, 5, 21); }
  { case 255: return (0, 1, -1, 10); }
% S16a (S XVI alpha)
  { case 256: return (4.7292, 1, 4.7134, 4.7449); }
  { case 257: return (0, 1, -100, 0); }
  { case 258: return (10, 1, 5, 19); }
  { case 259: return (0, 1, -1, 10); }
% S16b (S XVI beta)
  { case 260: return (3.9912, 1, 3.9779, 4.0045); }
  { case 261: return (0, 1, -100, 0); }
  { case 262: return (10, 1, 5, 16); }
  { case 263: return (0, 1, -1, 10); }
% S16g (S XVI gamma)
  { case 264: return (3.7845, 1, 3.7718, 3.7971); }
  { case 265: return (0, 1, -100, 0); }
  { case 266: return (10, 1, 5, 15); }
  { case 267: return (0, 1, -1, 10); }
% S16d (S XVI delta)
  { case 268: return (3.6959, 1, 3.6836, 3.7082); }
  { case 269: return (0, 1, -100, 0); }
  { case 270: return (10, 1, 5, 15); }
  { case 271: return (0, 1, -1, 10); }
% S15f (S XV f)
  { case 272: return (5.1015, 1, 5.0845, 5.1185); }
  { case 273: return (0, 1, -100, 0); }
  { case 274: return (10, 1, 5, 20); }
  { case 275: return (0, 1, -1, 10); }
% S15i (S XV i)
  { case 276: return (5.0665, 1, 5.0496, 5.0834); }
  { case 277: return (0, 1, -100, 0); }
  { case 278: return (10, 1, 5, 20); }
  { case 279: return (0, 1, -1, 10); }
% S15a (S XV alpha)
  { case 280: return (5.0387, 1, 5.0219, 5.0555); }
  { case 281: return (0, 1, -100, 0); }
  { case 282: return (10, 1, 5, 20); }
  { case 283: return (0, 1, -1, 10); }
% S15b (S XV beta)
  { case 284: return (4.2990, 1, 4.2847, 4.3133); }
  { case 285: return (0, 1, -100, 0); }
  { case 286: return (10, 1, 5, 17); }
  { case 287: return (0, 1, -1, 10); }
% S15g (S XV gamma)
  { case 288: return (4.0883, 1, 4.0747, 4.1019); }
  { case 289: return (0, 1, -100, 0); }
  { case 290: return (10, 1, 5, 16); }
  { case 291: return (0, 1, -1, 10); }
% S15d (S XV delta)
  { case 292: return (3.9980, 1, 3.9847, 4.0113); }
  { case 293: return (0, 1, -100, 0); }
  { case 294: return (10, 1, 5, 16); }
  { case 295: return (0, 1, -1, 10); }
% Ar18a (Ar XVIII alpha)
  { case 296: return (3.7329, 1, 3.7205, 3.7454); }
  { case 297: return (0, 1, -100, 0); }
  { case 298: return (10, 1, 5, 15); }
  { case 299: return (0, 1, -1, 10); }
% Ar18b (Ar XVIII beta)
  { case 300: return (3.1506, 1, 3.1401, 3.1611); }
  { case 301: return (0, 1, -100, 0); }
  { case 302: return (10, 1, 5, 13); }
  { case 303: return (0, 1, -1, 10); }
% Ar18g (Ar XVIII gamma)
  { case 304: return (2.9875, 1, 2.9775, 2.9974); }
  { case 305: return (0, 1, -100, 0); }
  { case 306: return (10, 1, 5, 12); }
  { case 307: return (0, 1, -1, 10); }
% Ar18d (Ar XVIII delta)
  { case 308: return (2.9176, 1, 2.9078, 2.9273); }
  { case 309: return (0, 1, -100, 0); }
  { case 310: return (10, 1, 5, 12); }
  { case 311: return (0, 1, -1, 10); }
% Ar17f (Ar XVII f)
  { case 312: return (3.9942, 1, 3.9808, 4.0075); }
  { case 313: return (0, 1, -100, 0); }
  { case 314: return (10, 1, 5, 16); }
  { case 315: return (0, 1, -1, 10); }
% Ar17i (Ar XVII i)
  { case 316: return (3.9694, 1, 3.9561, 3.9826); }
  { case 317: return (0, 1, -100, 0); }
  { case 318: return (10, 1, 5, 16); }
  { case 319: return (0, 1, -1, 10); }
% Ar17a (Ar XVII alpha)
  { case 320: return (3.9491, 1, 3.9359, 3.9622); }
  { case 321: return (0, 1, -100, 0); }
  { case 322: return (10, 1, 5, 16); }
  { case 323: return (0, 1, -1, 10); }
% Ar17b (Ar XVII beta)
  { case 324: return (3.3650, 1, 3.3538, 3.3762); }
  { case 325: return (0, 1, -100, 0); }
  { case 326: return (10, 1, 5, 13); }
  { case 327: return (0, 1, -1, 10); }
% Ar17g (Ar XVII gamma)
  { case 328: return (3.2000, 1, 3.1893, 3.2107); }
  { case 329: return (0, 1, -100, 0); }
  { case 330: return (10, 1, 5, 13); }
  { case 331: return (0, 1, -1, 10); }
% Ar17d (Ar XVII delta)
  { case 332: return (3.1280, 1, 3.1176, 3.1384); }
  { case 333: return (0, 1, -100, 0); }
  { case 334: return (10, 1, 5, 13); }
  { case 335: return (0, 1, -1, 10); }
% Ca20a (Ca XX alpha)
  { case 336: return (3.0203, 1, 3.0102, 3.0304); }
  { case 337: return (0, 1, -100, 0); }
  { case 338: return (10, 1, 5, 12); }
  { case 339: return (0, 1, -1, 10); }
% Ca20b (Ca XX beta)
  { case 340: return (2.5494, 1, 2.5409, 2.5579); }
  { case 341: return (0, 1, -100, 0); }
  { case 342: return (10, 1, 5, 10); }
  { case 343: return (0, 1, -1, 10); }
% Ca20g (Ca XX gamma)
  { case 344: return (2.4174, 1, 2.4093, 2.4255); }
  { case 345: return (0, 1, -100, 0); }
  { case 346: return (10, 1, 5, 10); }
  { case 347: return (0, 1, -1, 10); }
% Ca20d (Ca XX delta)
  { case 348: return (2.3609, 1, 2.3530, 2.3687); }
  { case 349: return (0, 1, -100, 0); }
  { case 350: return (9, 1, 5, 9); }
  { case 351: return (0, 1, -1, 10); }
% Ca19f (Ca XIX f)
  { case 352: return (3.2110, 1, 3.2003, 3.2217); }
  { case 353: return (0, 1, -100, 0); }
  { case 354: return (10, 1, 5, 13); }
  { case 355: return (0, 1, -1, 10); }
% Ca19i (Ca XIX i)
  { case 356: return (3.1927, 1, 3.1821, 3.2034); }
  { case 357: return (0, 1, -100, 0); }
  { case 358: return (10, 1, 5, 13); }
  { case 359: return (0, 1, -1, 10); }
% Ca19a (Ca XIX alpha)
  { case 360: return (3.1772, 1, 3.1666, 3.1877); }
  { case 361: return (0, 1, -100, 0); }
  { case 362: return (10, 1, 5, 13); }
  { case 363: return (0, 1, -1, 10); }
% Ca19b (Ca XIX beta)
  { case 364: return (2.7050, 1, 2.6960, 2.7140); }
  { case 365: return (0, 1, -100, 0); }
  { case 366: return (10, 1, 5, 11); }
  { case 367: return (0, 1, -1, 10); }
% Ca19g (Ca XIX gamma)
  { case 368: return (2.5710, 1, 2.5624, 2.5796); }
  { case 369: return (0, 1, -100, 0); }
  { case 370: return (10, 1, 5, 10); }
  { case 371: return (0, 1, -1, 10); }
% Ca19d (Ca XIX delta)
  { case 372: return (2.5140, 1, 2.5056, 2.5224); }
  { case 373: return (0, 1, -100, 0); }
  { case 374: return (10, 1, 5, 10); }
  { case 375: return (0, 1, -1, 10); }
% Fe26a (Fe XXVI alpha)
  { case 376: return (1.7799, 1, 1.7739, 1.7858); }
  { case 377: return (0, 1, -100, 0); }
  { case 378: return (7, 1, 5, 7); }
  { case 379: return (0, 1, -1, 10); }
% Fe26b (Fe XXVI beta)
  { case 380: return (1.5028, 1, 1.4977, 1.5078); }
  { case 381: return (0, 1, -100, 0); }
  { case 382: return (6, 1, 5, 6); }
  { case 383: return (0, 1, -1, 10); }
% Fe26g (Fe XXVI gamma)
  { case 384: return (1.4251, 1, 1.4203, 1.4298); }
  { case 385: return (0, 1, -100, 0); }
  { case 386: return (6, 1, 5, 6); }
  { case 387: return (0, 1, -1, 10); }
% Fe26d (Fe XXVI delta)
  { case 388: return (1.3918, 1, 1.3871, 1.3964); }
  { case 389: return (0, 1, -100, 0); }
  { case 390: return (6, 1, 5, 6); }
  { case 391: return (0, 1, -1, 10); }
% Fe25f (Fe XXV f)
  { case 392: return (1.8682, 1, 1.8620, 1.8744); }
  { case 393: return (0, 1, -100, 0); }
  { case 394: return (7, 1, 5, 7); }
  { case 395: return (0, 1, -1, 10); }
% Fe25i (Fe XXV i)
  { case 396: return (1.8595, 1, 1.8533, 1.8657); }
  { case 397: return (0, 1, -100, 0); }
  { case 398: return (7, 1, 5, 7); }
  { case 399: return (0, 1, -1, 10); }
% Fe25a (Fe XXV alpha)
  { case 400: return (1.8504, 1, 1.8442, 1.8566); }
  { case 401: return (0, 1, -100, 0); }
  { case 402: return (7, 1, 5, 7); }
  { case 403: return (0, 1, -1, 10); }
% Fe25b (Fe XXV beta)
  { case 404: return (1.5731, 1, 1.5679, 1.5783); }
  { case 405: return (0, 1, -100, 0); }
  { case 406: return (6, 1, 5, 6); }
  { case 407: return (0, 1, -1, 10); }
% Fe25g (Fe XXV gamma)
  { case 408: return (1.4950, 1, 1.4900, 1.5000); }
  { case 409: return (0, 1, -100, 0); }
  { case 410: return (6, 1, 5, 6); }
  { case 411: return (0, 1, -1, 10); }
% Fe25d (Fe XXV delta)
  { case 412: return (1.4610, 1, 1.4561, 1.4659); }
  { case 413: return (0, 1, -100, 0); }
  { case 414: return (6, 1, 5, 6); }
  { case 415: return (0, 1, -1, 10); }
% Fe1Ka (Fe I Kalpha)
  { case 416: return (1.9370, 1, 1.9305, 1.9435); }
  { case 417: return (0, 1, -100, 0); }
  { case 418: return (8, 1, 5, 8); }
  { case 419: return (0, 1, -1, 10); }
% Fe24_1062A (161758)
  { case 420: return (10.6190, 1, 10.5836, 10.6544); }
  { case 421: return (0, 1, -100, 0); }
  { case 422: return (10, 1, 5, 42); }
  { case 423: return (0, 1, -1, 10); }
% Fe24_679A (161756)
  { case 424: return (6.7887, 1, 6.7661, 6.8113); }
  { case 425: return (0, 1, -100, 0); }
  { case 426: return (10, 1, 5, 27); }
  { case 427: return (0, 1, -1, 10); }
% bl_1066A (161753, 18204) = (Fe XXIV, Fe XVII)
  { case 428: return (10.6600, 1, 10.6245, 10.6955); }
  { case 429: return (0, 1, -100, 0); }
  { case 430: return (10, 1, 5, 43); }
  { case 431: return (0, 1, -1, 10); }
% Fe24_799A (161759, 161754)
  { case 432: return (7.9908, 1, 7.9642, 8.0175); }
  { case 433: return (0, 1, -100, 0); }
  { case 434: return (10, 1, 5, 32); }
  { case 435: return (0, 1, -1, 10); }
% bl_1102A (149890, 18163) = (Fe XXIII, Fe XVII)
  { case 436: return (11.0225, 1, 10.9858, 11.0592); }
  { case 437: return (0, 1, -100, 0); }
  { case 438: return (10, 1, 5, 44); }
  { case 439: return (0, 1, -1, 10); }
% bl_1099A (149893, 131886) = (Fe XXIII, Fe XXII)
  { case 440: return (10.9872, 1, 10.9506, 11.0239); }
  { case 441: return (0, 1, -100, 0); }
  { case 442: return (10, 1, 5, 44); }
  { case 443: return (0, 1, -1, 10); }
% Fe23_830A (149914)
  { case 444: return (8.3038, 1, 8.2761, 8.3315); }
  { case 445: return (0, 1, -100, 0); }
  { case 446: return (10, 1, 5, 33); }
  { case 447: return (0, 1, -1, 10); }
% Fe22_1225A (131880)
  { case 448: return (12.2519, 1, 12.2111, 12.2927); }
  { case 449: return (0, 1, -100, 0); }
  { case 450: return (10, 1, 5, 49); }
  { case 451: return (0, 1, -1, 10); }
% Fe22_1143A (132636)
  { case 452: return (11.4270, 1, 11.3889, 11.4651); }
  { case 453: return (0, 1, -100, 0); }
  { case 454: return (10, 1, 5, 46); }
  { case 455: return (0, 1, -1, 10); }
% Fe22_897A (132642)
  { case 456: return (8.9748, 1, 8.9449, 9.0047); }
  { case 457: return (0, 1, -100, 0); }
  { case 458: return (10, 1, 5, 36); }
  { case 459: return (0, 1, -1, 10); }
% Fe22_1193A (132890)
  { case 460: return (11.9320, 1, 11.8922, 11.9718); }
  { case 461: return (0, 1, -100, 0); }
  { case 462: return (10, 1, 5, 48); }
  { case 463: return (0, 1, -1, 10); }
% bl_1177A (132626, 75499) = (Fe XXII, Fe XX)
  { case 464: return (11.7660, 1, 11.7268, 11.8052); }
  { case 465: return (0, 1, -100, 0); }
  { case 466: return (10, 1, 5, 47); }
  { case 467: return (0, 1, -1, 10); }
% Fe22_1149A (131888, 132634)
  { case 468: return (11.4900, 1, 11.4517, 11.5283); }
  { case 469: return (0, 1, -100, 0); }
  { case 470: return (10, 1, 5, 46); }
  { case 471: return (0, 1, -1, 10); }
% Fe22_873A (131902, 132644)
  { case 472: return (8.7307, 1, 8.7016, 8.7598); }
  { case 473: return (0, 1, -100, 0); }
  { case 474: return (10, 1, 5, 35); }
  { case 475: return (0, 1, -1, 10); }
% Fe22_786A (131918, 132676)
  { case 476: return (7.8650, 1, 7.8388, 7.8912); }
  { case 477: return (0, 1, -100, 0); }
  { case 478: return (10, 1, 5, 31); }
  { case 479: return (0, 1, -1, 10); }
% Fe21_1228A (128657)
  { case 480: return (12.2840, 1, 12.2431, 12.3249); }
  { case 481: return (0, 1, -100, 0); }
  { case 482: return (10, 1, 5, 49); }
  { case 483: return (0, 1, -1, 10); }
% Fe21_1198A (128681)
  { case 484: return (11.9750, 1, 11.9351, 12.0149); }
  { case 485: return (0, 1, -100, 0); }
  { case 486: return (10, 1, 5, 48); }
  { case 487: return (0, 1, -1, 10); }
% Fe21_1304A (128653)
  { case 488: return (13.0444, 1, 13.0009, 13.0879); }
  { case 489: return (0, 1, -100, 0); }
  { case 490: return (10, 1, 5, 52); }
  { case 491: return (0, 1, -1, 10); }
% bl_920A (128775, 75070, 74587) = (Fe XXI, Fe XX, Fe XX)
  { case 492: return (9.1967, 1, 9.1661, 9.2274); }
  { case 493: return (0, 1, -100, 0); }
  { case 494: return (10, 1, 5, 37); }
  { case 495: return (0, 1, -1, 10); }
% Fe21_857A (128847, 131702, 129682)
  { case 496: return (8.5740, 1, 8.5454, 8.6026); }
  { case 497: return (0, 1, -100, 0); }
  { case 498: return (10, 1, 5, 34); }
  { case 499: return (0, 1, -1, 10); }
% Fe21_1233A (131540)
  { case 500: return (12.3270, 1, 12.2859, 12.3681); }
  { case 501: return (0, 1, -100, 0); }
  { case 502: return (10, 1, 5, 49); }
  { case 503: return (0, 1, -1, 10); }
% Fe20_1292A (75469, 74908)
  { case 504: return (12.9165, 1, 12.8735, 12.9596); }
  { case 505: return (0, 1, -100, 0); }
  { case 506: return (10, 1, 5, 52); }
  { case 507: return (0, 1, -1, 10); }
% Fe20_1286A (74900, 75472)
  { case 508: return (12.8550, 1, 12.8121, 12.8978); }
  { case 509: return (0, 1, -100, 0); }
  { case 510: return (10, 1, 5, 51); }
  { case 511: return (0, 1, -1, 10); }
% Fe20_1283A (74354, 74360)
  { case 512: return (12.8255, 1, 12.7827, 12.8683); }
  { case 513: return (0, 1, -100, 0); }
  { case 514: return (10, 1, 5, 51); }
  { case 515: return (0, 1, -1, 10); }
% Fe20_1258A (74924, 75496)
  { case 516: return (12.5760, 1, 12.5341, 12.6179); }
  { case 517: return (0, 1, -100, 0); }
  { case 518: return (10, 1, 5, 50); }
  { case 519: return (0, 1, -1, 10); }
% Fe20_1000A (74457, 75036, 74463, 75579)
  { case 520: return (9.9992, 1, 9.9659, 10.0326); }
  { case 521: return (0, 1, -100, 0); }
  { case 522: return (10, 1, 5, 40); }
  { case 523: return (0, 1, -1, 10); }
% Fe20_1297A (75461, 74351)
  { case 524: return (12.9652, 1, 12.9220, 13.0084); }
  { case 525: return (0, 1, -100, 0); }
  { case 526: return (10, 1, 5, 52); }
  { case 527: return (0, 1, -1, 10); }
% bl_1012A (75587, 39003, 18189) = (Fe XX, Fe XIX, Fe XVII)
  { case 528: return (10.1203, 1, 10.0865, 10.1540); }
  { case 529: return (0, 1, -100, 0); }
  { case 530: return (10, 1, 5, 40); }
  { case 531: return (0, 1, -1, 10); }
% bl_1301A (74897, 39144) = (Fe XX, Fe XIX)
  { case 532: return (13.0070, 1, 12.9636, 13.0504); }
  { case 533: return (0, 1, -100, 0); }
  { case 534: return (10, 1, 5, 52); }
  { case 535: return (0, 1, -1, 10); }
% Fe19_1466A (39118)
  { case 536: return (14.6640, 1, 14.6151, 14.7129); }
  { case 537: return (0, 1, -100, 0); }
  { case 538: return (10, 1, 5, 59); }
  { case 539: return (0, 1, -1, 10); }
% Fe19_1380A (39132)
  { case 540: return (13.7950, 1, 13.7490, 13.8410); }
  { case 541: return (0, 1, -100, 0); }
  { case 542: return (10, 1, 5, 55); }
  { case 543: return (0, 1, -1, 10); }
% Fe19_1364A (39124)
  { case 544: return (13.6450, 1, 13.5995, 13.6905); }
  { case 545: return (0, 1, -100, 0); }
  { case 546: return (10, 1, 5, 55); }
  { case 547: return (0, 1, -1, 10); }
% Fe19_1350A (38915)
  { case 548: return (13.4970, 1, 13.4520, 13.5420); }
  { case 549: return (0, 1, -100, 0); }
  { case 550: return (10, 1, 5, 54); }
  { case 551: return (0, 1, -1, 10); }
% Fe19_1346A (38603)
  { case 552: return (13.4620, 1, 13.4171, 13.5069); }
  { case 553: return (0, 1, -100, 0); }
  { case 554: return (10, 1, 5, 54); }
  { case 555: return (0, 1, -1, 10); }
% Fe19_1342A (39134)
  { case 556: return (13.4230, 1, 13.3783, 13.4677); }
  { case 557: return (0, 1, -100, 0); }
  { case 558: return (10, 1, 5, 54); }
  { case 559: return (0, 1, -1, 10); }
% Fe19_1294A (38634)
  { case 560: return (12.9450, 1, 12.9018, 12.9881); }
  { case 561: return (0, 1, -100, 0); }
  { case 562: return (10, 1, 5, 52); }
  { case 563: return (0, 1, -1, 10); }
% Fe19_1082A (39172)
  { case 564: return (10.8160, 1, 10.7799, 10.8521); }
  { case 565: return (0, 1, -100, 0); }
  { case 566: return (10, 1, 5, 43); }
  { case 567: return (0, 1, -1, 10); }
% Fe19_1013A (38692)
  { case 568: return (10.1309, 1, 10.0971, 10.1647); }
  { case 569: return (0, 1, -100, 0); }
  { case 570: return (10, 1, 5, 41); }
  { case 571: return (0, 1, -1, 10); }
% Fe19_986A (39223)
  { case 572: return (9.8552, 1, 9.8224, 9.8881); }
  { case 573: return (0, 1, -100, 0); }
  { case 574: return (10, 1, 5, 39); }
  { case 575: return (0, 1, -1, 10); }
% Fe19_1352A (39128, 38611)
  { case 576: return (13.5163, 1, 13.4712, 13.5614); }
  { case 577: return (0, 1, -100, 0); }
  { case 578: return (10, 1, 5, 54); }
  { case 579: return (0, 1, -1, 10); }
% Fe19_1293A (38941, 39146)
  { case 580: return (12.9320, 1, 12.8889, 12.9752); }
  { case 581: return (0, 1, -100, 0); }
  { case 582: return (10, 1, 5, 52); }
  { case 583: return (0, 1, -1, 10); }
% Fe18_1453A (38000)
  { case 584: return (14.5340, 1, 14.4856, 14.5824); }
  { case 585: return (0, 1, -100, 0); }
  { case 586: return (10, 1, 5, 58); }
  { case 587: return (0, 1, -1, 10); }
% Fe18_1437A (37997)
  { case 588: return (14.3730, 1, 14.3251, 14.4209); }
  { case 589: return (0, 1, -100, 0); }
  { case 590: return (10, 1, 5, 57); }
  { case 591: return (0, 1, -1, 10); }
% Fe18_1457A (37942)
  { case 592: return (14.5710, 1, 14.5224, 14.6196); }
  { case 593: return (0, 1, -100, 0); }
  { case 594: return (10, 1, 5, 58); }
  { case 595: return (0, 1, -1, 10); }
% Fe18_1562A (37995)
  { case 596: return (15.6250, 1, 15.5729, 15.6771); }
  { case 597: return (0, 1, -100, 0); }
  { case 598: return (10, 1, 5, 62); }
  { case 599: return (0, 1, -1, 10); }
% Fe18_1332A (37835)
  { case 600: return (13.3230, 1, 13.2786, 13.3674); }
  { case 601: return (0, 1, -100, 0); }
  { case 602: return (10, 1, 5, 53); }
  { case 603: return (0, 1, -1, 10); }
% Fe18_1426A (37830, 38002)
  { case 604: return (14.2560, 1, 14.2085, 14.3035); }
  { case 605: return (0, 1, -100, 0); }
  { case 606: return (10, 1, 5, 57); }
  { case 607: return (0, 1, -1, 10); }
% Fe18_1421A (37944, 37998, 38112)
  { case 608: return (14.2056, 1, 14.1582, 14.2529); }
  { case 609: return (0, 1, -100, 0); }
  { case 610: return (10, 1, 5, 57); }
  { case 611: return (0, 1, -1, 10); }
% Fe18_1153A (37961, 38014)
  { case 612: return (11.5270, 1, 11.4886, 11.5654); }
  { case 613: return (0, 1, -100, 0); }
  { case 614: return (10, 1, 5, 46); }
  { case 615: return (0, 1, -1, 10); }
% Fe18_1133A (37845, 37963, 38012)
  { case 616: return (11.3260, 1, 11.2882, 11.3638); }
  { case 617: return (0, 1, -100, 0); }
  { case 618: return (10, 1, 5, 45); }
  { case 619: return (0, 1, -1, 10); }
% Fe17_1678A (20125)
  { case 620: return (16.7800, 1, 16.7241, 16.8359); }
  { case 621: return (0, 1, -100, 0); }
  { case 622: return (10, 1, 5, 67); }
  { case 623: return (0, 1, -1, 10); }
% Fe17_1526A (20128)
  { case 624: return (15.2610, 1, 15.2101, 15.3119); }
  { case 625: return (0, 1, -100, 0); }
  { case 626: return (10, 1, 5, 61); }
  { case 627: return (0, 1, -1, 10); }
% Fe17_1501A (20127)
  { case 628: return (15.0140, 1, 14.9640, 15.0640); }
  { case 629: return (0, 1, -100, 0); }
  { case 630: return (10, 1, 5, 60); }
  { case 631: return (0, 1, -1, 10); }
% Fe17_1227A (18155)
  { case 632: return (12.2660, 1, 12.2251, 12.3069); }
  { case 633: return (0, 1, -100, 0); }
  { case 634: return (10, 1, 5, 49); }
  { case 635: return (0, 1, -1, 10); }
% Fe17_1212A (18151)
  { case 636: return (12.1240, 1, 12.0836, 12.1644); }
  { case 637: return (0, 1, -100, 0); }
  { case 638: return (10, 1, 5, 48); }
  { case 639: return (0, 1, -1, 10); }
% Fe17_1536A (25066)
  { case 640: return (15.3597, 1, 15.3085, 15.4109); }
  { case 641: return (0, 1, -100, 0); }
  { case 642: return (10, 1, 5, 61); }
  { case 643: return (0, 1, -1, 10); }
% Fe17_1382A (20130)
  { case 644: return (13.8250, 1, 13.7789, 13.8711); }
  { case 645: return (0, 1, -100, 0); }
  { case 646: return (10, 1, 5, 55); }
  { case 647: return (0, 1, -1, 10); }
% bl_1384A (38918, 74885) = (Fe XIX, Fe XX)
  { case 648: return (13.8410, 1, 13.7949, 13.8871); }
  { case 649: return (0, 1, -100, 0); }
  { case 650: return (10, 1, 5, 55); }
  { case 651: return (0, 1, -1, 10); }
% Al11Ka (Al XI Kalpha)
  { case 652: return (7.8850, 1, 7.8587, 7.9113); }
  { case 653: return (0, 1, -100, 0); }
  { case 654: return (10, 1, 5, 32); }
  { case 655: return (0, 1, -1, 10); }
% Al10Ka (Al X Kalpha)
  { case 656: return (7.9640, 1, 7.9375, 7.9905); }
  { case 657: return (0, 1, -100, 0); }
  { case 658: return (10, 1, 5, 32); }
  { case 659: return (0, 1, -1, 10); }
% Al9Ka (Al IX Kalpha)
  { case 660: return (8.0500, 1, 8.0232, 8.0768); }
  { case 661: return (0, 1, -100, 0); }
  { case 662: return (10, 1, 5, 32); }
  { case 663: return (0, 1, -1, 10); }
% Al8Ka (Al VIII Kalpha)
  { case 664: return (8.1290, 1, 8.1019, 8.1561); }
  { case 665: return (0, 1, -100, 0); }
  { case 666: return (10, 1, 5, 33); }
  { case 667: return (0, 1, -1, 10); }
% Al7Ka (Al VII Kalpha)
  { case 668: return (8.2030, 1, 8.1757, 8.2303); }
  { case 669: return (0, 1, -100, 0); }
  { case 670: return (10, 1, 5, 33); }
  { case 671: return (0, 1, -1, 10); }
% Al6Ka (Al VI Kalpha)
  { case 672: return (8.2690, 1, 8.2414, 8.2966); }
  { case 673: return (0, 1, -100, 0); }
  { case 674: return (10, 1, 5, 33); }
  { case 675: return (0, 1, -1, 10); }
% Al5Ka (Al V Kalpha)
  { case 676: return (8.3280, 1, 8.3002, 8.3558); }
  { case 677: return (0, 1, -100, 0); }
  { case 678: return (10, 1, 5, 33); }
  { case 679: return (0, 1, -1, 10); }
% Al4Ka (Al IV Kalpha)
  { case 680: return (8.3320, 1, 8.3042, 8.3598); }
  { case 681: return (0, 1, -100, 0); }
  { case 682: return (10, 1, 5, 33); }
  { case 683: return (0, 1, -1, 10); }
% Al3Ka (Al III Kalpha)
  { case 684: return (8.3360, 1, 8.3082, 8.3638); }
  { case 685: return (0, 1, -100, 0); }
  { case 686: return (10, 1, 5, 33); }
  { case 687: return (0, 1, -1, 10); }
% Al2Ka (Al II Kalpha)
  { case 688: return (8.3390, 1, 8.3112, 8.3668); }
  { case 689: return (0, 1, -100, 0); }
  { case 690: return (10, 1, 5, 33); }
  { case 691: return (0, 1, -1, 10); }
% Si12Ka (Si XII Kalpha)
  { case 692: return (6.7500, 1, 6.7275, 6.7725); }
  { case 693: return (0, 1, -100, 0); }
  { case 694: return (10, 1, 5, 27); }
  { case 695: return (0, 1, -1, 10); }
% Si11Ka (Si XI Kalpha)
  { case 696: return (6.8130, 1, 6.7903, 6.8357); }
  { case 697: return (0, 1, -100, 0); }
  { case 698: return (10, 1, 5, 27); }
  { case 699: return (0, 1, -1, 10); }
% Si10Ka (Si X Kalpha)
  { case 700: return (6.8820, 1, 6.8591, 6.9049); }
  { case 701: return (0, 1, -100, 0); }
  { case 702: return (10, 1, 5, 28); }
  { case 703: return (0, 1, -1, 10); }
% Si9Ka (Si IX Kalpha)
  { case 704: return (6.9470, 1, 6.9238, 6.9702); }
  { case 705: return (0, 1, -100, 0); }
  { case 706: return (10, 1, 5, 28); }
  { case 707: return (0, 1, -1, 10); }
% Si8Ka (Si VIII Kalpha)
  { case 708: return (7.0070, 1, 6.9836, 7.0304); }
  { case 709: return (0, 1, -100, 0); }
  { case 710: return (10, 1, 5, 28); }
  { case 711: return (0, 1, -1, 10); }
% Si7Ka (Si VII Kalpha)
  { case 712: return (7.0630, 1, 7.0395, 7.0865); }
  { case 713: return (0, 1, -100, 0); }
  { case 714: return (10, 1, 5, 28); }
  { case 715: return (0, 1, -1, 10); }
% Si6Ka (Si VI Kalpha)
  { case 716: return (7.1120, 1, 7.0883, 7.1357); }
  { case 717: return (0, 1, -100, 0); }
  { case 718: return (10, 1, 5, 28); }
  { case 719: return (0, 1, -1, 10); }
% Si5Ka (Si V Kalpha)
  { case 720: return (7.1170, 1, 7.0933, 7.1407); }
  { case 721: return (0, 1, -100, 0); }
  { case 722: return (10, 1, 5, 28); }
  { case 723: return (0, 1, -1, 10); }
% Si4Ka (Si IV Kalpha)
  { case 724: return (7.1210, 1, 7.0973, 7.1447); }
  { case 725: return (0, 1, -100, 0); }
  { case 726: return (10, 1, 5, 28); }
  { case 727: return (0, 1, -1, 10); }
% Si3Ka (Si III Kalpha)
  { case 728: return (7.1240, 1, 7.1003, 7.1477); }
  { case 729: return (0, 1, -100, 0); }
  { case 730: return (10, 1, 5, 28); }
  { case 731: return (0, 1, -1, 10); }
% Si2Ka (Si II Kalpha)
  { case 732: return (7.1260, 1, 7.1022, 7.1498); }
  { case 733: return (0, 1, -100, 0); }
  { case 734: return (10, 1, 5, 29); }
  { case 735: return (0, 1, -1, 10); }
% Ar16Ka (Ar XVI Kalpha)
  { case 736: return (3.9950, 1, 3.9817, 4.0083); }
  { case 737: return (0, 1, -100, 0); }
  { case 738: return (10, 1, 5, 16); }
  { case 739: return (0, 1, -1, 10); }
% Ar15Ka (Ar XV Kalpha)
  { case 740: return (4.0250, 1, 4.0116, 4.0384); }
  { case 741: return (0, 1, -100, 0); }
  { case 742: return (10, 1, 5, 16); }
  { case 743: return (0, 1, -1, 10); }
% Ar14Ka (Ar XIV Kalpha)
  { case 744: return (4.0570, 1, 4.0435, 4.0705); }
  { case 745: return (0, 1, -100, 0); }
  { case 746: return (10, 1, 5, 16); }
  { case 747: return (0, 1, -1, 10); }
% Ar13Ka (Ar XIII Kalpha)
  { case 748: return (4.0890, 1, 4.0754, 4.1026); }
  { case 749: return (0, 1, -100, 0); }
  { case 750: return (10, 1, 5, 16); }
  { case 751: return (0, 1, -1, 10); }
% Ar12Ka (Ar XII Kalpha)
  { case 752: return (4.1190, 1, 4.1053, 4.1327); }
  { case 753: return (0, 1, -100, 0); }
  { case 754: return (10, 1, 5, 16); }
  { case 755: return (0, 1, -1, 10); }
% Ar11Ka (Ar XI Kalpha)
  { case 756: return (4.1470, 1, 4.1332, 4.1608); }
  { case 757: return (0, 1, -100, 0); }
  { case 758: return (10, 1, 5, 17); }
  { case 759: return (0, 1, -1, 10); }
% Ar10Ka (Ar X Kalpha)
  { case 760: return (4.1740, 1, 4.1601, 4.1879); }
  { case 761: return (0, 1, -100, 0); }
  { case 762: return (10, 1, 5, 17); }
  { case 763: return (0, 1, -1, 10); }
% Ar9Ka (Ar IX Kalpha)
  { case 764: return (4.1780, 1, 4.1641, 4.1919); }
  { case 765: return (0, 1, -100, 0); }
  { case 766: return (10, 1, 5, 17); }
  { case 767: return (0, 1, -1, 10); }
% Ar8Ka (Ar VIII Kalpha)
  { case 768: return (4.1800, 1, 4.1661, 4.1939); }
  { case 769: return (0, 1, -100, 0); }
  { case 770: return (10, 1, 5, 17); }
  { case 771: return (0, 1, -1, 10); }
% Ar7Ka (Ar VII Kalpha)
  { case 772: return (4.1840, 1, 4.1701, 4.1979); }
  { case 773: return (0, 1, -100, 0); }
  { case 774: return (10, 1, 5, 17); }
  { case 775: return (0, 1, -1, 10); }
% Ar6Ka (Ar VI Kalpha)
  { case 776: return (4.1860, 1, 4.1720, 4.2000); }
  { case 777: return (0, 1, -100, 0); }
  { case 778: return (10, 1, 5, 17); }
  { case 779: return (0, 1, -1, 10); }
% Ar5Ka (Ar V Kalpha)
  { case 780: return (4.1890, 1, 4.1750, 4.2030); }
  { case 781: return (0, 1, -100, 0); }
  { case 782: return (10, 1, 5, 17); }
  { case 783: return (0, 1, -1, 10); }
% Ar4Ka (Ar IV Kalpha)
  { case 784: return (4.1900, 1, 4.1760, 4.2040); }
  { case 785: return (0, 1, -100, 0); }
  { case 786: return (10, 1, 5, 17); }
  { case 787: return (0, 1, -1, 10); }
% Ar3Ka (Ar III Kalpha)
  { case 788: return (4.1920, 1, 4.1780, 4.2060); }
  { case 789: return (0, 1, -100, 0); }
  { case 790: return (10, 1, 5, 17); }
  { case 791: return (0, 1, -1, 10); }
% Ar2Ka (Ar II Kalpha)
  { case 792: return (4.1930, 1, 4.1790, 4.2070); }
  { case 793: return (0, 1, -100, 0); }
  { case 794: return (10, 1, 5, 17); }
  { case 795: return (0, 1, -1, 10); }
}

add_slang_function("lines",
[
         "O8a_lam [A (18.9689 A)]",         "O8a_EW [mA]",         "O8a_FWHM [mA]",         "O8a_A",  %  @ 18.9689 A (O VIII alpha)
         "O8b_lam [A (16.0059 A)]",         "O8b_EW [mA]",         "O8b_FWHM [mA]",         "O8b_A",  %  @ 16.0059 A (O VIII beta)
         "O8g_lam [A (15.1762 A)]",         "O8g_EW [mA]",         "O8g_FWHM [mA]",         "O8g_A",  %  @ 15.1762 A (O VIII gamma)
         "O8d_lam [A (14.8206 A)]",         "O8d_EW [mA]",         "O8d_FWHM [mA]",         "O8d_A",  %  @ 14.8206 A (O VIII delta)
         "O7f_lam [A (22.0977 A)]",         "O7f_EW [mA]",         "O7f_FWHM [mA]",         "O7f_A",  %  @ 22.0977 A (O VII f)
         "O7i_lam [A (21.8036 A)]",         "O7i_EW [mA]",         "O7i_FWHM [mA]",         "O7i_A",  %  @ 21.8036 A (O VII i)
         "O7a_lam [A (21.6015 A)]",         "O7a_EW [mA]",         "O7a_FWHM [mA]",         "O7a_A",  %  @ 21.6015 A (O VII alpha)
         "O7b_lam [A (18.6270 A)]",         "O7b_EW [mA]",         "O7b_FWHM [mA]",         "O7b_A",  %  @ 18.6270 A (O VII beta)
         "O7g_lam [A (17.7680 A)]",         "O7g_EW [mA]",         "O7g_FWHM [mA]",         "O7g_A",  %  @ 17.7680 A (O VII gamma)
         "O7d_lam [A (17.3960 A)]",         "O7d_EW [mA]",         "O7d_FWHM [mA]",         "O7d_A",  %  @ 17.3960 A (O VII delta)
       "Ne10a_lam [A (12.1339 A)]",       "Ne10a_EW [mA]",       "Ne10a_FWHM [mA]",       "Ne10a_A",  %  @ 12.1339 A (Ne X alpha)
       "Ne10b_lam [A (10.2389 A)]",       "Ne10b_EW [mA]",       "Ne10b_FWHM [mA]",       "Ne10b_A",  %  @ 10.2389 A (Ne X beta)
       "Ne10g_lam [A ( 9.7082 A)]",       "Ne10g_EW [mA]",       "Ne10g_FWHM [mA]",       "Ne10g_A",  %  @  9.7082 A (Ne X gamma)
       "Ne10d_lam [A ( 9.4807 A)]",       "Ne10d_EW [mA]",       "Ne10d_FWHM [mA]",       "Ne10d_A",  %  @  9.4807 A (Ne X delta)
       "Ne10e_lam [A ( 9.3616 A)]",       "Ne10e_EW [mA]",       "Ne10e_FWHM [mA]",       "Ne10e_A",  %  @  9.3616 A (Ne X epsilon)
       "Ne10z_lam [A ( 9.2912 A)]",       "Ne10z_EW [mA]",       "Ne10z_FWHM [mA]",       "Ne10z_A",  %  @  9.2912 A (Ne X zeta)
        "Ne9f_lam [A (13.6990 A)]",        "Ne9f_EW [mA]",        "Ne9f_FWHM [mA]",        "Ne9f_A",  %  @ 13.6990 A (Ne IX f)
        "Ne9i_lam [A (13.5531 A)]",        "Ne9i_EW [mA]",        "Ne9i_FWHM [mA]",        "Ne9i_A",  %  @ 13.5531 A (Ne IX i)
        "Ne9a_lam [A (13.4473 A)]",        "Ne9a_EW [mA]",        "Ne9a_FWHM [mA]",        "Ne9a_A",  %  @ 13.4473 A (Ne IX alpha)
        "Ne9b_lam [A (11.5440 A)]",        "Ne9b_EW [mA]",        "Ne9b_FWHM [mA]",        "Ne9b_A",  %  @ 11.5440 A (Ne IX beta)
        "Ne9g_lam [A (11.0010 A)]",        "Ne9g_EW [mA]",        "Ne9g_FWHM [mA]",        "Ne9g_A",  %  @ 11.0010 A (Ne IX gamma)
        "Ne9d_lam [A (10.7650 A)]",        "Ne9d_EW [mA]",        "Ne9d_FWHM [mA]",        "Ne9d_A",  %  @ 10.7650 A (Ne IX delta)
        "Ne9e_lam [A (10.6426 A)]",        "Ne9e_EW [mA]",        "Ne9e_FWHM [mA]",        "Ne9e_A",  %  @ 10.6426 A (Ne IX epsilon)
        "Ne9z_lam [A (10.5650 A)]",        "Ne9z_EW [mA]",        "Ne9z_FWHM [mA]",        "Ne9z_A",  %  @ 10.5650 A (Ne IX zeta)
       "Na11a_lam [A (10.0250 A)]",       "Na11a_EW [mA]",       "Na11a_FWHM [mA]",       "Na11a_A",  %  @ 10.0250 A (Na XI alpha)
       "Na11b_lam [A ( 8.4595 A)]",       "Na11b_EW [mA]",       "Na11b_FWHM [mA]",       "Na11b_A",  %  @  8.4595 A (Na XI beta)
       "Na11g_lam [A ( 8.0211 A)]",       "Na11g_EW [mA]",       "Na11g_FWHM [mA]",       "Na11g_A",  %  @  8.0211 A (Na XI gamma)
       "Na11d_lam [A ( 7.8332 A)]",       "Na11d_EW [mA]",       "Na11d_FWHM [mA]",       "Na11d_A",  %  @  7.8332 A (Na XI delta)
       "Na10f_lam [A (11.1900 A)]",       "Na10f_EW [mA]",       "Na10f_FWHM [mA]",       "Na10f_A",  %  @ 11.1900 A (Na X f)
       "Na10i_lam [A (11.0800 A)]",       "Na10i_EW [mA]",       "Na10i_FWHM [mA]",       "Na10i_A",  %  @ 11.0800 A (Na X i)
       "Na10a_lam [A (11.0027 A)]",       "Na10a_EW [mA]",       "Na10a_FWHM [mA]",       "Na10a_A",  %  @ 11.0027 A (Na X alpha)
       "Na10b_lam [A ( 9.4330 A)]",       "Na10b_EW [mA]",       "Na10b_FWHM [mA]",       "Na10b_A",  %  @  9.4330 A (Na X beta)
       "Na10g_lam [A ( 8.9828 A)]",       "Na10g_EW [mA]",       "Na10g_FWHM [mA]",       "Na10g_A",  %  @  8.9828 A (Na X gamma)
       "Na10d_lam [A ( 8.7884 A)]",       "Na10d_EW [mA]",       "Na10d_FWHM [mA]",       "Na10d_A",  %  @  8.7884 A (Na X delta)
       "Mg12a_lam [A ( 8.4210 A)]",       "Mg12a_EW [mA]",       "Mg12a_FWHM [mA]",       "Mg12a_A",  %  @  8.4210 A (Mg XII alpha)
       "Mg12b_lam [A ( 7.1062 A)]",       "Mg12b_EW [mA]",       "Mg12b_FWHM [mA]",       "Mg12b_A",  %  @  7.1062 A (Mg XII beta)
       "Mg12g_lam [A ( 6.7379 A)]",       "Mg12g_EW [mA]",       "Mg12g_FWHM [mA]",       "Mg12g_A",  %  @  6.7379 A (Mg XII gamma)
       "Mg12d_lam [A ( 6.5801 A)]",       "Mg12d_EW [mA]",       "Mg12d_FWHM [mA]",       "Mg12d_A",  %  @  6.5801 A (Mg XII delta)
       "Mg11f_lam [A ( 9.3143 A)]",       "Mg11f_EW [mA]",       "Mg11f_FWHM [mA]",       "Mg11f_A",  %  @  9.3143 A (Mg XI f)
       "Mg11i_lam [A ( 9.2312 A)]",       "Mg11i_EW [mA]",       "Mg11i_FWHM [mA]",       "Mg11i_A",  %  @  9.2312 A (Mg XI i)
       "Mg11a_lam [A ( 9.1687 A)]",       "Mg11a_EW [mA]",       "Mg11a_FWHM [mA]",       "Mg11a_A",  %  @  9.1687 A (Mg XI alpha)
       "Mg11b_lam [A ( 7.8503 A)]",       "Mg11b_EW [mA]",       "Mg11b_FWHM [mA]",       "Mg11b_A",  %  @  7.8503 A (Mg XI beta)
       "Mg11g_lam [A ( 7.4730 A)]",       "Mg11g_EW [mA]",       "Mg11g_FWHM [mA]",       "Mg11g_A",  %  @  7.4730 A (Mg XI gamma)
       "Mg11d_lam [A ( 7.3101 A)]",       "Mg11d_EW [mA]",       "Mg11d_FWHM [mA]",       "Mg11d_A",  %  @  7.3101 A (Mg XI delta)
       "Al13a_lam [A ( 7.1728 A)]",       "Al13a_EW [mA]",       "Al13a_FWHM [mA]",       "Al13a_A",  %  @  7.1728 A (Al XIII alpha)
       "Al13b_lam [A ( 6.0530 A)]",       "Al13b_EW [mA]",       "Al13b_FWHM [mA]",       "Al13b_A",  %  @  6.0530 A (Al XIII beta)
       "Al13g_lam [A ( 5.7393 A)]",       "Al13g_EW [mA]",       "Al13g_FWHM [mA]",       "Al13g_A",  %  @  5.7393 A (Al XIII gamma)
       "Al13d_lam [A ( 5.6049 A)]",       "Al13d_EW [mA]",       "Al13d_FWHM [mA]",       "Al13d_A",  %  @  5.6049 A (Al XIII delta)
       "Al12f_lam [A ( 7.8721 A)]",       "Al12f_EW [mA]",       "Al12f_FWHM [mA]",       "Al12f_A",  %  @  7.8721 A (Al XII f)
       "Al12i_lam [A ( 7.8070 A)]",       "Al12i_EW [mA]",       "Al12i_FWHM [mA]",       "Al12i_A",  %  @  7.8070 A (Al XII i)
       "Al12a_lam [A ( 7.7573 A)]",       "Al12a_EW [mA]",       "Al12a_FWHM [mA]",       "Al12a_A",  %  @  7.7573 A (Al XII alpha)
       "Al12b_lam [A ( 6.6350 A)]",       "Al12b_EW [mA]",       "Al12b_FWHM [mA]",       "Al12b_A",  %  @  6.6350 A (Al XII beta)
       "Al12g_lam [A ( 6.3140 A)]",       "Al12g_EW [mA]",       "Al12g_FWHM [mA]",       "Al12g_A",  %  @  6.3140 A (Al XII gamma)
       "Al12d_lam [A ( 6.1750 A)]",       "Al12d_EW [mA]",       "Al12d_FWHM [mA]",       "Al12d_A",  %  @  6.1750 A (Al XII delta)
       "Si14a_lam [A ( 6.1822 A)]",       "Si14a_EW [mA]",       "Si14a_FWHM [mA]",       "Si14a_A",  %  @  6.1822 A (Si XIV alpha)
       "Si14b_lam [A ( 5.2172 A)]",       "Si14b_EW [mA]",       "Si14b_FWHM [mA]",       "Si14b_A",  %  @  5.2172 A (Si XIV beta)
       "Si14g_lam [A ( 4.9469 A)]",       "Si14g_EW [mA]",       "Si14g_FWHM [mA]",       "Si14g_A",  %  @  4.9469 A (Si XIV gamma)
       "Si14d_lam [A ( 4.8311 A)]",       "Si14d_EW [mA]",       "Si14d_FWHM [mA]",       "Si14d_A",  %  @  4.8311 A (Si XIV delta)
       "Si13f_lam [A ( 6.7403 A)]",       "Si13f_EW [mA]",       "Si13f_FWHM [mA]",       "Si13f_A",  %  @  6.7403 A (Si XIII f)
       "Si13i_lam [A ( 6.6882 A)]",       "Si13i_EW [mA]",       "Si13i_FWHM [mA]",       "Si13i_A",  %  @  6.6882 A (Si XIII i)
       "Si13a_lam [A ( 6.6479 A)]",       "Si13a_EW [mA]",       "Si13a_FWHM [mA]",       "Si13a_A",  %  @  6.6479 A (Si XIII alpha)
       "Si13b_lam [A ( 5.6805 A)]",       "Si13b_EW [mA]",       "Si13b_FWHM [mA]",       "Si13b_A",  %  @  5.6805 A (Si XIII beta)
       "Si13g_lam [A ( 5.4045 A)]",       "Si13g_EW [mA]",       "Si13g_FWHM [mA]",       "Si13g_A",  %  @  5.4045 A (Si XIII gamma)
       "Si13d_lam [A ( 5.2850 A)]",       "Si13d_EW [mA]",       "Si13d_FWHM [mA]",       "Si13d_A",  %  @  5.2850 A (Si XIII delta)
        "S16a_lam [A ( 4.7292 A)]",        "S16a_EW [mA]",        "S16a_FWHM [mA]",        "S16a_A",  %  @  4.7292 A (S XVI alpha)
        "S16b_lam [A ( 3.9912 A)]",        "S16b_EW [mA]",        "S16b_FWHM [mA]",        "S16b_A",  %  @  3.9912 A (S XVI beta)
        "S16g_lam [A ( 3.7845 A)]",        "S16g_EW [mA]",        "S16g_FWHM [mA]",        "S16g_A",  %  @  3.7845 A (S XVI gamma)
        "S16d_lam [A ( 3.6959 A)]",        "S16d_EW [mA]",        "S16d_FWHM [mA]",        "S16d_A",  %  @  3.6959 A (S XVI delta)
        "S15f_lam [A ( 5.1015 A)]",        "S15f_EW [mA]",        "S15f_FWHM [mA]",        "S15f_A",  %  @  5.1015 A (S XV f)
        "S15i_lam [A ( 5.0665 A)]",        "S15i_EW [mA]",        "S15i_FWHM [mA]",        "S15i_A",  %  @  5.0665 A (S XV i)
        "S15a_lam [A ( 5.0387 A)]",        "S15a_EW [mA]",        "S15a_FWHM [mA]",        "S15a_A",  %  @  5.0387 A (S XV alpha)
        "S15b_lam [A ( 4.2990 A)]",        "S15b_EW [mA]",        "S15b_FWHM [mA]",        "S15b_A",  %  @  4.2990 A (S XV beta)
        "S15g_lam [A ( 4.0883 A)]",        "S15g_EW [mA]",        "S15g_FWHM [mA]",        "S15g_A",  %  @  4.0883 A (S XV gamma)
        "S15d_lam [A ( 3.9980 A)]",        "S15d_EW [mA]",        "S15d_FWHM [mA]",        "S15d_A",  %  @  3.9980 A (S XV delta)
       "Ar18a_lam [A ( 3.7329 A)]",       "Ar18a_EW [mA]",       "Ar18a_FWHM [mA]",       "Ar18a_A",  %  @  3.7329 A (Ar XVIII alpha)
       "Ar18b_lam [A ( 3.1506 A)]",       "Ar18b_EW [mA]",       "Ar18b_FWHM [mA]",       "Ar18b_A",  %  @  3.1506 A (Ar XVIII beta)
       "Ar18g_lam [A ( 2.9875 A)]",       "Ar18g_EW [mA]",       "Ar18g_FWHM [mA]",       "Ar18g_A",  %  @  2.9875 A (Ar XVIII gamma)
       "Ar18d_lam [A ( 2.9176 A)]",       "Ar18d_EW [mA]",       "Ar18d_FWHM [mA]",       "Ar18d_A",  %  @  2.9176 A (Ar XVIII delta)
       "Ar17f_lam [A ( 3.9942 A)]",       "Ar17f_EW [mA]",       "Ar17f_FWHM [mA]",       "Ar17f_A",  %  @  3.9942 A (Ar XVII f)
       "Ar17i_lam [A ( 3.9694 A)]",       "Ar17i_EW [mA]",       "Ar17i_FWHM [mA]",       "Ar17i_A",  %  @  3.9694 A (Ar XVII i)
       "Ar17a_lam [A ( 3.9491 A)]",       "Ar17a_EW [mA]",       "Ar17a_FWHM [mA]",       "Ar17a_A",  %  @  3.9491 A (Ar XVII alpha)
       "Ar17b_lam [A ( 3.3650 A)]",       "Ar17b_EW [mA]",       "Ar17b_FWHM [mA]",       "Ar17b_A",  %  @  3.3650 A (Ar XVII beta)
       "Ar17g_lam [A ( 3.2000 A)]",       "Ar17g_EW [mA]",       "Ar17g_FWHM [mA]",       "Ar17g_A",  %  @  3.2000 A (Ar XVII gamma)
       "Ar17d_lam [A ( 3.1280 A)]",       "Ar17d_EW [mA]",       "Ar17d_FWHM [mA]",       "Ar17d_A",  %  @  3.1280 A (Ar XVII delta)
       "Ca20a_lam [A ( 3.0203 A)]",       "Ca20a_EW [mA]",       "Ca20a_FWHM [mA]",       "Ca20a_A",  %  @  3.0203 A (Ca XX alpha)
       "Ca20b_lam [A ( 2.5494 A)]",       "Ca20b_EW [mA]",       "Ca20b_FWHM [mA]",       "Ca20b_A",  %  @  2.5494 A (Ca XX beta)
       "Ca20g_lam [A ( 2.4174 A)]",       "Ca20g_EW [mA]",       "Ca20g_FWHM [mA]",       "Ca20g_A",  %  @  2.4174 A (Ca XX gamma)
       "Ca20d_lam [A ( 2.3609 A)]",       "Ca20d_EW [mA]",       "Ca20d_FWHM [mA]",       "Ca20d_A",  %  @  2.3609 A (Ca XX delta)
       "Ca19f_lam [A ( 3.2110 A)]",       "Ca19f_EW [mA]",       "Ca19f_FWHM [mA]",       "Ca19f_A",  %  @  3.2110 A (Ca XIX f)
       "Ca19i_lam [A ( 3.1927 A)]",       "Ca19i_EW [mA]",       "Ca19i_FWHM [mA]",       "Ca19i_A",  %  @  3.1927 A (Ca XIX i)
       "Ca19a_lam [A ( 3.1772 A)]",       "Ca19a_EW [mA]",       "Ca19a_FWHM [mA]",       "Ca19a_A",  %  @  3.1772 A (Ca XIX alpha)
       "Ca19b_lam [A ( 2.7050 A)]",       "Ca19b_EW [mA]",       "Ca19b_FWHM [mA]",       "Ca19b_A",  %  @  2.7050 A (Ca XIX beta)
       "Ca19g_lam [A ( 2.5710 A)]",       "Ca19g_EW [mA]",       "Ca19g_FWHM [mA]",       "Ca19g_A",  %  @  2.5710 A (Ca XIX gamma)
       "Ca19d_lam [A ( 2.5140 A)]",       "Ca19d_EW [mA]",       "Ca19d_FWHM [mA]",       "Ca19d_A",  %  @  2.5140 A (Ca XIX delta)
       "Fe26a_lam [A ( 1.7799 A)]",       "Fe26a_EW [mA]",       "Fe26a_FWHM [mA]",       "Fe26a_A",  %  @  1.7799 A (Fe XXVI alpha)
       "Fe26b_lam [A ( 1.5028 A)]",       "Fe26b_EW [mA]",       "Fe26b_FWHM [mA]",       "Fe26b_A",  %  @  1.5028 A (Fe XXVI beta)
       "Fe26g_lam [A ( 1.4251 A)]",       "Fe26g_EW [mA]",       "Fe26g_FWHM [mA]",       "Fe26g_A",  %  @  1.4251 A (Fe XXVI gamma)
       "Fe26d_lam [A ( 1.3918 A)]",       "Fe26d_EW [mA]",       "Fe26d_FWHM [mA]",       "Fe26d_A",  %  @  1.3918 A (Fe XXVI delta)
       "Fe25f_lam [A ( 1.8682 A)]",       "Fe25f_EW [mA]",       "Fe25f_FWHM [mA]",       "Fe25f_A",  %  @  1.8682 A (Fe XXV f)
       "Fe25i_lam [A ( 1.8595 A)]",       "Fe25i_EW [mA]",       "Fe25i_FWHM [mA]",       "Fe25i_A",  %  @  1.8595 A (Fe XXV i)
       "Fe25a_lam [A ( 1.8504 A)]",       "Fe25a_EW [mA]",       "Fe25a_FWHM [mA]",       "Fe25a_A",  %  @  1.8504 A (Fe XXV alpha)
       "Fe25b_lam [A ( 1.5731 A)]",       "Fe25b_EW [mA]",       "Fe25b_FWHM [mA]",       "Fe25b_A",  %  @  1.5731 A (Fe XXV beta)
       "Fe25g_lam [A ( 1.4950 A)]",       "Fe25g_EW [mA]",       "Fe25g_FWHM [mA]",       "Fe25g_A",  %  @  1.4950 A (Fe XXV gamma)
       "Fe25d_lam [A ( 1.4610 A)]",       "Fe25d_EW [mA]",       "Fe25d_FWHM [mA]",       "Fe25d_A",  %  @  1.4610 A (Fe XXV delta)
       "Fe1Ka_lam [A ( 1.9370 A)]",       "Fe1Ka_EW [mA]",       "Fe1Ka_FWHM [mA]",       "Fe1Ka_A",  %  @  1.9370 A (Fe I Kalpha)
  "Fe24_1062A_lam [A (10.6190 A)]",  "Fe24_1062A_EW [mA]",  "Fe24_1062A_FWHM [mA]",  "Fe24_1062A_A",  %  @ 10.6190 A (161758)
   "Fe24_679A_lam [A ( 6.7887 A)]",   "Fe24_679A_EW [mA]",   "Fe24_679A_FWHM [mA]",   "Fe24_679A_A",  %  @  6.7887 A (161756)
    "bl_1066A_lam [A (10.6600 A)]",    "bl_1066A_EW [mA]",    "bl_1066A_FWHM [mA]",    "bl_1066A_A",  %  @ 10.6600 A (161753, 18204) = (Fe XXIV, Fe XVII)
   "Fe24_799A_lam [A ( 7.9908 A)]",   "Fe24_799A_EW [mA]",   "Fe24_799A_FWHM [mA]",   "Fe24_799A_A",  %  @  7.9908 A (161759, 161754)
    "bl_1102A_lam [A (11.0225 A)]",    "bl_1102A_EW [mA]",    "bl_1102A_FWHM [mA]",    "bl_1102A_A",  %  @ 11.0225 A (149890, 18163) = (Fe XXIII, Fe XVII)
    "bl_1099A_lam [A (10.9872 A)]",    "bl_1099A_EW [mA]",    "bl_1099A_FWHM [mA]",    "bl_1099A_A",  %  @ 10.9872 A (149893, 131886) = (Fe XXIII, Fe XXII)
   "Fe23_830A_lam [A ( 8.3038 A)]",   "Fe23_830A_EW [mA]",   "Fe23_830A_FWHM [mA]",   "Fe23_830A_A",  %  @  8.3038 A (149914)
  "Fe22_1225A_lam [A (12.2519 A)]",  "Fe22_1225A_EW [mA]",  "Fe22_1225A_FWHM [mA]",  "Fe22_1225A_A",  %  @ 12.2519 A (131880)
  "Fe22_1143A_lam [A (11.4270 A)]",  "Fe22_1143A_EW [mA]",  "Fe22_1143A_FWHM [mA]",  "Fe22_1143A_A",  %  @ 11.4270 A (132636)
   "Fe22_897A_lam [A ( 8.9748 A)]",   "Fe22_897A_EW [mA]",   "Fe22_897A_FWHM [mA]",   "Fe22_897A_A",  %  @  8.9748 A (132642)
  "Fe22_1193A_lam [A (11.9320 A)]",  "Fe22_1193A_EW [mA]",  "Fe22_1193A_FWHM [mA]",  "Fe22_1193A_A",  %  @ 11.9320 A (132890)
    "bl_1177A_lam [A (11.7660 A)]",    "bl_1177A_EW [mA]",    "bl_1177A_FWHM [mA]",    "bl_1177A_A",  %  @ 11.7660 A (132626, 75499) = (Fe XXII, Fe XX)
  "Fe22_1149A_lam [A (11.4900 A)]",  "Fe22_1149A_EW [mA]",  "Fe22_1149A_FWHM [mA]",  "Fe22_1149A_A",  %  @ 11.4900 A (131888, 132634)
   "Fe22_873A_lam [A ( 8.7307 A)]",   "Fe22_873A_EW [mA]",   "Fe22_873A_FWHM [mA]",   "Fe22_873A_A",  %  @  8.7307 A (131902, 132644)
   "Fe22_786A_lam [A ( 7.8650 A)]",   "Fe22_786A_EW [mA]",   "Fe22_786A_FWHM [mA]",   "Fe22_786A_A",  %  @  7.8650 A (131918, 132676)
  "Fe21_1228A_lam [A (12.2840 A)]",  "Fe21_1228A_EW [mA]",  "Fe21_1228A_FWHM [mA]",  "Fe21_1228A_A",  %  @ 12.2840 A (128657)
  "Fe21_1198A_lam [A (11.9750 A)]",  "Fe21_1198A_EW [mA]",  "Fe21_1198A_FWHM [mA]",  "Fe21_1198A_A",  %  @ 11.9750 A (128681)
  "Fe21_1304A_lam [A (13.0444 A)]",  "Fe21_1304A_EW [mA]",  "Fe21_1304A_FWHM [mA]",  "Fe21_1304A_A",  %  @ 13.0444 A (128653)
     "bl_920A_lam [A ( 9.1967 A)]",     "bl_920A_EW [mA]",     "bl_920A_FWHM [mA]",     "bl_920A_A",  %  @  9.1967 A (128775, 75070, 74587) = (Fe XXI, Fe XX, Fe XX)
   "Fe21_857A_lam [A ( 8.5740 A)]",   "Fe21_857A_EW [mA]",   "Fe21_857A_FWHM [mA]",   "Fe21_857A_A",  %  @  8.5740 A (128847, 131702, 129682)
  "Fe21_1233A_lam [A (12.3270 A)]",  "Fe21_1233A_EW [mA]",  "Fe21_1233A_FWHM [mA]",  "Fe21_1233A_A",  %  @ 12.3270 A (131540)
  "Fe20_1292A_lam [A (12.9165 A)]",  "Fe20_1292A_EW [mA]",  "Fe20_1292A_FWHM [mA]",  "Fe20_1292A_A",  %  @ 12.9165 A (75469, 74908)
  "Fe20_1286A_lam [A (12.8550 A)]",  "Fe20_1286A_EW [mA]",  "Fe20_1286A_FWHM [mA]",  "Fe20_1286A_A",  %  @ 12.8550 A (74900, 75472)
  "Fe20_1283A_lam [A (12.8255 A)]",  "Fe20_1283A_EW [mA]",  "Fe20_1283A_FWHM [mA]",  "Fe20_1283A_A",  %  @ 12.8255 A (74354, 74360)
  "Fe20_1258A_lam [A (12.5760 A)]",  "Fe20_1258A_EW [mA]",  "Fe20_1258A_FWHM [mA]",  "Fe20_1258A_A",  %  @ 12.5760 A (74924, 75496)
  "Fe20_1000A_lam [A ( 9.9992 A)]",  "Fe20_1000A_EW [mA]",  "Fe20_1000A_FWHM [mA]",  "Fe20_1000A_A",  %  @  9.9992 A (74457, 75036, 74463, 75579)
  "Fe20_1297A_lam [A (12.9652 A)]",  "Fe20_1297A_EW [mA]",  "Fe20_1297A_FWHM [mA]",  "Fe20_1297A_A",  %  @ 12.9652 A (75461, 74351)
    "bl_1012A_lam [A (10.1203 A)]",    "bl_1012A_EW [mA]",    "bl_1012A_FWHM [mA]",    "bl_1012A_A",  %  @ 10.1203 A (75587, 39003, 18189) = (Fe XX, Fe XIX, Fe XVII)
    "bl_1301A_lam [A (13.0070 A)]",    "bl_1301A_EW [mA]",    "bl_1301A_FWHM [mA]",    "bl_1301A_A",  %  @ 13.0070 A (74897, 39144) = (Fe XX, Fe XIX)
  "Fe19_1466A_lam [A (14.6640 A)]",  "Fe19_1466A_EW [mA]",  "Fe19_1466A_FWHM [mA]",  "Fe19_1466A_A",  %  @ 14.6640 A (39118)
  "Fe19_1380A_lam [A (13.7950 A)]",  "Fe19_1380A_EW [mA]",  "Fe19_1380A_FWHM [mA]",  "Fe19_1380A_A",  %  @ 13.7950 A (39132)
  "Fe19_1364A_lam [A (13.6450 A)]",  "Fe19_1364A_EW [mA]",  "Fe19_1364A_FWHM [mA]",  "Fe19_1364A_A",  %  @ 13.6450 A (39124)
  "Fe19_1350A_lam [A (13.4970 A)]",  "Fe19_1350A_EW [mA]",  "Fe19_1350A_FWHM [mA]",  "Fe19_1350A_A",  %  @ 13.4970 A (38915)
  "Fe19_1346A_lam [A (13.4620 A)]",  "Fe19_1346A_EW [mA]",  "Fe19_1346A_FWHM [mA]",  "Fe19_1346A_A",  %  @ 13.4620 A (38603)
  "Fe19_1342A_lam [A (13.4230 A)]",  "Fe19_1342A_EW [mA]",  "Fe19_1342A_FWHM [mA]",  "Fe19_1342A_A",  %  @ 13.4230 A (39134)
  "Fe19_1294A_lam [A (12.9450 A)]",  "Fe19_1294A_EW [mA]",  "Fe19_1294A_FWHM [mA]",  "Fe19_1294A_A",  %  @ 12.9450 A (38634)
  "Fe19_1082A_lam [A (10.8160 A)]",  "Fe19_1082A_EW [mA]",  "Fe19_1082A_FWHM [mA]",  "Fe19_1082A_A",  %  @ 10.8160 A (39172)
  "Fe19_1013A_lam [A (10.1309 A)]",  "Fe19_1013A_EW [mA]",  "Fe19_1013A_FWHM [mA]",  "Fe19_1013A_A",  %  @ 10.1309 A (38692)
   "Fe19_986A_lam [A ( 9.8552 A)]",   "Fe19_986A_EW [mA]",   "Fe19_986A_FWHM [mA]",   "Fe19_986A_A",  %  @  9.8552 A (39223)
  "Fe19_1352A_lam [A (13.5163 A)]",  "Fe19_1352A_EW [mA]",  "Fe19_1352A_FWHM [mA]",  "Fe19_1352A_A",  %  @ 13.5163 A (39128, 38611)
  "Fe19_1293A_lam [A (12.9320 A)]",  "Fe19_1293A_EW [mA]",  "Fe19_1293A_FWHM [mA]",  "Fe19_1293A_A",  %  @ 12.9320 A (38941, 39146)
  "Fe18_1453A_lam [A (14.5340 A)]",  "Fe18_1453A_EW [mA]",  "Fe18_1453A_FWHM [mA]",  "Fe18_1453A_A",  %  @ 14.5340 A (38000)
  "Fe18_1437A_lam [A (14.3730 A)]",  "Fe18_1437A_EW [mA]",  "Fe18_1437A_FWHM [mA]",  "Fe18_1437A_A",  %  @ 14.3730 A (37997)
  "Fe18_1457A_lam [A (14.5710 A)]",  "Fe18_1457A_EW [mA]",  "Fe18_1457A_FWHM [mA]",  "Fe18_1457A_A",  %  @ 14.5710 A (37942)
  "Fe18_1562A_lam [A (15.6250 A)]",  "Fe18_1562A_EW [mA]",  "Fe18_1562A_FWHM [mA]",  "Fe18_1562A_A",  %  @ 15.6250 A (37995)
  "Fe18_1332A_lam [A (13.3230 A)]",  "Fe18_1332A_EW [mA]",  "Fe18_1332A_FWHM [mA]",  "Fe18_1332A_A",  %  @ 13.3230 A (37835)
  "Fe18_1426A_lam [A (14.2560 A)]",  "Fe18_1426A_EW [mA]",  "Fe18_1426A_FWHM [mA]",  "Fe18_1426A_A",  %  @ 14.2560 A (37830, 38002)
  "Fe18_1421A_lam [A (14.2056 A)]",  "Fe18_1421A_EW [mA]",  "Fe18_1421A_FWHM [mA]",  "Fe18_1421A_A",  %  @ 14.2056 A (37944, 37998, 38112)
  "Fe18_1153A_lam [A (11.5270 A)]",  "Fe18_1153A_EW [mA]",  "Fe18_1153A_FWHM [mA]",  "Fe18_1153A_A",  %  @ 11.5270 A (37961, 38014)
  "Fe18_1133A_lam [A (11.3260 A)]",  "Fe18_1133A_EW [mA]",  "Fe18_1133A_FWHM [mA]",  "Fe18_1133A_A",  %  @ 11.3260 A (37845, 37963, 38012)
  "Fe17_1678A_lam [A (16.7800 A)]",  "Fe17_1678A_EW [mA]",  "Fe17_1678A_FWHM [mA]",  "Fe17_1678A_A",  %  @ 16.7800 A (20125)
  "Fe17_1526A_lam [A (15.2610 A)]",  "Fe17_1526A_EW [mA]",  "Fe17_1526A_FWHM [mA]",  "Fe17_1526A_A",  %  @ 15.2610 A (20128)
  "Fe17_1501A_lam [A (15.0140 A)]",  "Fe17_1501A_EW [mA]",  "Fe17_1501A_FWHM [mA]",  "Fe17_1501A_A",  %  @ 15.0140 A (20127)
  "Fe17_1227A_lam [A (12.2660 A)]",  "Fe17_1227A_EW [mA]",  "Fe17_1227A_FWHM [mA]",  "Fe17_1227A_A",  %  @ 12.2660 A (18155)
  "Fe17_1212A_lam [A (12.1240 A)]",  "Fe17_1212A_EW [mA]",  "Fe17_1212A_FWHM [mA]",  "Fe17_1212A_A",  %  @ 12.1240 A (18151)
  "Fe17_1536A_lam [A (15.3597 A)]",  "Fe17_1536A_EW [mA]",  "Fe17_1536A_FWHM [mA]",  "Fe17_1536A_A",  %  @ 15.3597 A (25066)
  "Fe17_1382A_lam [A (13.8250 A)]",  "Fe17_1382A_EW [mA]",  "Fe17_1382A_FWHM [mA]",  "Fe17_1382A_A",  %  @ 13.8250 A (20130)
    "bl_1384A_lam [A (13.8410 A)]",    "bl_1384A_EW [mA]",    "bl_1384A_FWHM [mA]",    "bl_1384A_A",  %  @ 13.8410 A (38918, 74885) = (Fe XIX, Fe XX)
      "Al11Ka_lam [A ( 7.8850 A)]",      "Al11Ka_EW [mA]",      "Al11Ka_FWHM [mA]",      "Al11Ka_A",  %  @  7.8850 A (Al XI Kalpha)
      "Al10Ka_lam [A ( 7.9640 A)]",      "Al10Ka_EW [mA]",      "Al10Ka_FWHM [mA]",      "Al10Ka_A",  %  @  7.9640 A (Al X Kalpha)
       "Al9Ka_lam [A ( 8.0500 A)]",       "Al9Ka_EW [mA]",       "Al9Ka_FWHM [mA]",       "Al9Ka_A",  %  @  8.0500 A (Al IX Kalpha)
       "Al8Ka_lam [A ( 8.1290 A)]",       "Al8Ka_EW [mA]",       "Al8Ka_FWHM [mA]",       "Al8Ka_A",  %  @  8.1290 A (Al VIII Kalpha)
       "Al7Ka_lam [A ( 8.2030 A)]",       "Al7Ka_EW [mA]",       "Al7Ka_FWHM [mA]",       "Al7Ka_A",  %  @  8.2030 A (Al VII Kalpha)
       "Al6Ka_lam [A ( 8.2690 A)]",       "Al6Ka_EW [mA]",       "Al6Ka_FWHM [mA]",       "Al6Ka_A",  %  @  8.2690 A (Al VI Kalpha)
       "Al5Ka_lam [A ( 8.3280 A)]",       "Al5Ka_EW [mA]",       "Al5Ka_FWHM [mA]",       "Al5Ka_A",  %  @  8.3280 A (Al V Kalpha)
       "Al4Ka_lam [A ( 8.3320 A)]",       "Al4Ka_EW [mA]",       "Al4Ka_FWHM [mA]",       "Al4Ka_A",  %  @  8.3320 A (Al IV Kalpha)
       "Al3Ka_lam [A ( 8.3360 A)]",       "Al3Ka_EW [mA]",       "Al3Ka_FWHM [mA]",       "Al3Ka_A",  %  @  8.3360 A (Al III Kalpha)
       "Al2Ka_lam [A ( 8.3390 A)]",       "Al2Ka_EW [mA]",       "Al2Ka_FWHM [mA]",       "Al2Ka_A",  %  @  8.3390 A (Al II Kalpha)
      "Si12Ka_lam [A ( 6.7500 A)]",      "Si12Ka_EW [mA]",      "Si12Ka_FWHM [mA]",      "Si12Ka_A",  %  @  6.7500 A (Si XII Kalpha)
      "Si11Ka_lam [A ( 6.8130 A)]",      "Si11Ka_EW [mA]",      "Si11Ka_FWHM [mA]",      "Si11Ka_A",  %  @  6.8130 A (Si XI Kalpha)
      "Si10Ka_lam [A ( 6.8820 A)]",      "Si10Ka_EW [mA]",      "Si10Ka_FWHM [mA]",      "Si10Ka_A",  %  @  6.8820 A (Si X Kalpha)
       "Si9Ka_lam [A ( 6.9470 A)]",       "Si9Ka_EW [mA]",       "Si9Ka_FWHM [mA]",       "Si9Ka_A",  %  @  6.9470 A (Si IX Kalpha)
       "Si8Ka_lam [A ( 7.0070 A)]",       "Si8Ka_EW [mA]",       "Si8Ka_FWHM [mA]",       "Si8Ka_A",  %  @  7.0070 A (Si VIII Kalpha)
       "Si7Ka_lam [A ( 7.0630 A)]",       "Si7Ka_EW [mA]",       "Si7Ka_FWHM [mA]",       "Si7Ka_A",  %  @  7.0630 A (Si VII Kalpha)
       "Si6Ka_lam [A ( 7.1120 A)]",       "Si6Ka_EW [mA]",       "Si6Ka_FWHM [mA]",       "Si6Ka_A",  %  @  7.1120 A (Si VI Kalpha)
       "Si5Ka_lam [A ( 7.1170 A)]",       "Si5Ka_EW [mA]",       "Si5Ka_FWHM [mA]",       "Si5Ka_A",  %  @  7.1170 A (Si V Kalpha)
       "Si4Ka_lam [A ( 7.1210 A)]",       "Si4Ka_EW [mA]",       "Si4Ka_FWHM [mA]",       "Si4Ka_A",  %  @  7.1210 A (Si IV Kalpha)
       "Si3Ka_lam [A ( 7.1240 A)]",       "Si3Ka_EW [mA]",       "Si3Ka_FWHM [mA]",       "Si3Ka_A",  %  @  7.1240 A (Si III Kalpha)
       "Si2Ka_lam [A ( 7.1260 A)]",       "Si2Ka_EW [mA]",       "Si2Ka_FWHM [mA]",       "Si2Ka_A",  %  @  7.1260 A (Si II Kalpha)
      "Ar16Ka_lam [A ( 3.9950 A)]",      "Ar16Ka_EW [mA]",      "Ar16Ka_FWHM [mA]",      "Ar16Ka_A",  %  @  3.9950 A (Ar XVI Kalpha)
      "Ar15Ka_lam [A ( 4.0250 A)]",      "Ar15Ka_EW [mA]",      "Ar15Ka_FWHM [mA]",      "Ar15Ka_A",  %  @  4.0250 A (Ar XV Kalpha)
      "Ar14Ka_lam [A ( 4.0570 A)]",      "Ar14Ka_EW [mA]",      "Ar14Ka_FWHM [mA]",      "Ar14Ka_A",  %  @  4.0570 A (Ar XIV Kalpha)
      "Ar13Ka_lam [A ( 4.0890 A)]",      "Ar13Ka_EW [mA]",      "Ar13Ka_FWHM [mA]",      "Ar13Ka_A",  %  @  4.0890 A (Ar XIII Kalpha)
      "Ar12Ka_lam [A ( 4.1190 A)]",      "Ar12Ka_EW [mA]",      "Ar12Ka_FWHM [mA]",      "Ar12Ka_A",  %  @  4.1190 A (Ar XII Kalpha)
      "Ar11Ka_lam [A ( 4.1470 A)]",      "Ar11Ka_EW [mA]",      "Ar11Ka_FWHM [mA]",      "Ar11Ka_A",  %  @  4.1470 A (Ar XI Kalpha)
      "Ar10Ka_lam [A ( 4.1740 A)]",      "Ar10Ka_EW [mA]",      "Ar10Ka_FWHM [mA]",      "Ar10Ka_A",  %  @  4.1740 A (Ar X Kalpha)
       "Ar9Ka_lam [A ( 4.1780 A)]",       "Ar9Ka_EW [mA]",       "Ar9Ka_FWHM [mA]",       "Ar9Ka_A",  %  @  4.1780 A (Ar IX Kalpha)
       "Ar8Ka_lam [A ( 4.1800 A)]",       "Ar8Ka_EW [mA]",       "Ar8Ka_FWHM [mA]",       "Ar8Ka_A",  %  @  4.1800 A (Ar VIII Kalpha)
       "Ar7Ka_lam [A ( 4.1840 A)]",       "Ar7Ka_EW [mA]",       "Ar7Ka_FWHM [mA]",       "Ar7Ka_A",  %  @  4.1840 A (Ar VII Kalpha)
       "Ar6Ka_lam [A ( 4.1860 A)]",       "Ar6Ka_EW [mA]",       "Ar6Ka_FWHM [mA]",       "Ar6Ka_A",  %  @  4.1860 A (Ar VI Kalpha)
       "Ar5Ka_lam [A ( 4.1890 A)]",       "Ar5Ka_EW [mA]",       "Ar5Ka_FWHM [mA]",       "Ar5Ka_A",  %  @  4.1890 A (Ar V Kalpha)
       "Ar4Ka_lam [A ( 4.1900 A)]",       "Ar4Ka_EW [mA]",       "Ar4Ka_FWHM [mA]",       "Ar4Ka_A",  %  @  4.1900 A (Ar IV Kalpha)
       "Ar3Ka_lam [A ( 4.1920 A)]",       "Ar3Ka_EW [mA]",       "Ar3Ka_FWHM [mA]",       "Ar3Ka_A",  %  @  4.1920 A (Ar III Kalpha)
       "Ar2Ka_lam [A ( 4.1930 A)]",       "Ar2Ka_EW [mA]",       "Ar2Ka_FWHM [mA]",       "Ar2Ka_A",  %  @  4.1930 A (Ar II Kalpha)
]);
set_param_default_hook("lines", "lines_defaults");


%%%%%%%%%%%%%%%%%%%%%%%%%%
define set_lines_par_fun()
%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{set_lines_par_fun}
%\synopsis{sets the derived amplitude parameter in a lines-model}
%\usage{set_lines_par_fun([Integer_Type id]);}
%\description
%    The amplitude parameters of the lines-model are set for every line:\n
%    \code{set_par_fun("lines(id).line_A", "lines(id).line_EW/lines(id).line_FWHM");}\n
%    If code{id} is not specified, id=1 is used.
%\seealso{gauss, lines, unset_lines_par_fun}
%!%-
{
  variable id=1;
  switch(_NARGS)
  { case 0: ; }
  { case 1: id = (); }
  { help(_function_name()); return; }

  variable lines = "lines("+string(id)+").";
  % Amplitude = EW/[sigma*sqrt{2*pi}] = EW/FWHM * 2*sqrt{ln(2)/pi}
  set_par_fun(lines+"O8a_A", lines+"O8a_EW/"+lines+"O8a_FWHM*0.9394372787");
  set_par_fun(lines+"O8b_A", lines+"O8b_EW/"+lines+"O8b_FWHM*0.9394372787");
  set_par_fun(lines+"O8g_A", lines+"O8g_EW/"+lines+"O8g_FWHM*0.9394372787");
  set_par_fun(lines+"O8d_A", lines+"O8d_EW/"+lines+"O8d_FWHM*0.9394372787");
  set_par_fun(lines+"O7f_A", lines+"O7f_EW/"+lines+"O7f_FWHM*0.9394372787");
  set_par_fun(lines+"O7i_A", lines+"O7i_EW/"+lines+"O7i_FWHM*0.9394372787");
  set_par_fun(lines+"O7a_A", lines+"O7a_EW/"+lines+"O7a_FWHM*0.9394372787");
  set_par_fun(lines+"O7b_A", lines+"O7b_EW/"+lines+"O7b_FWHM*0.9394372787");
  set_par_fun(lines+"O7g_A", lines+"O7g_EW/"+lines+"O7g_FWHM*0.9394372787");
  set_par_fun(lines+"O7d_A", lines+"O7d_EW/"+lines+"O7d_FWHM*0.9394372787");
  set_par_fun(lines+"Ne10a_A", lines+"Ne10a_EW/"+lines+"Ne10a_FWHM*0.9394372787");
  set_par_fun(lines+"Ne10b_A", lines+"Ne10b_EW/"+lines+"Ne10b_FWHM*0.9394372787");
  set_par_fun(lines+"Ne10g_A", lines+"Ne10g_EW/"+lines+"Ne10g_FWHM*0.9394372787");
  set_par_fun(lines+"Ne10d_A", lines+"Ne10d_EW/"+lines+"Ne10d_FWHM*0.9394372787");
  set_par_fun(lines+"Ne10e_A", lines+"Ne10e_EW/"+lines+"Ne10e_FWHM*0.9394372787");
  set_par_fun(lines+"Ne10z_A", lines+"Ne10z_EW/"+lines+"Ne10z_FWHM*0.9394372787");
  set_par_fun(lines+"Ne9f_A", lines+"Ne9f_EW/"+lines+"Ne9f_FWHM*0.9394372787");
  set_par_fun(lines+"Ne9i_A", lines+"Ne9i_EW/"+lines+"Ne9i_FWHM*0.9394372787");
  set_par_fun(lines+"Ne9a_A", lines+"Ne9a_EW/"+lines+"Ne9a_FWHM*0.9394372787");
  set_par_fun(lines+"Ne9b_A", lines+"Ne9b_EW/"+lines+"Ne9b_FWHM*0.9394372787");
  set_par_fun(lines+"Ne9g_A", lines+"Ne9g_EW/"+lines+"Ne9g_FWHM*0.9394372787");
  set_par_fun(lines+"Ne9d_A", lines+"Ne9d_EW/"+lines+"Ne9d_FWHM*0.9394372787");
  set_par_fun(lines+"Ne9e_A", lines+"Ne9e_EW/"+lines+"Ne9e_FWHM*0.9394372787");
  set_par_fun(lines+"Ne9z_A", lines+"Ne9z_EW/"+lines+"Ne9z_FWHM*0.9394372787");
  set_par_fun(lines+"Na11a_A", lines+"Na11a_EW/"+lines+"Na11a_FWHM*0.9394372787");
  set_par_fun(lines+"Na11b_A", lines+"Na11b_EW/"+lines+"Na11b_FWHM*0.9394372787");
  set_par_fun(lines+"Na11g_A", lines+"Na11g_EW/"+lines+"Na11g_FWHM*0.9394372787");
  set_par_fun(lines+"Na11d_A", lines+"Na11d_EW/"+lines+"Na11d_FWHM*0.9394372787");
  set_par_fun(lines+"Na10f_A", lines+"Na10f_EW/"+lines+"Na10f_FWHM*0.9394372787");
  set_par_fun(lines+"Na10i_A", lines+"Na10i_EW/"+lines+"Na10i_FWHM*0.9394372787");
  set_par_fun(lines+"Na10a_A", lines+"Na10a_EW/"+lines+"Na10a_FWHM*0.9394372787");
  set_par_fun(lines+"Na10b_A", lines+"Na10b_EW/"+lines+"Na10b_FWHM*0.9394372787");
  set_par_fun(lines+"Na10g_A", lines+"Na10g_EW/"+lines+"Na10g_FWHM*0.9394372787");
  set_par_fun(lines+"Na10d_A", lines+"Na10d_EW/"+lines+"Na10d_FWHM*0.9394372787");
  set_par_fun(lines+"Mg12a_A", lines+"Mg12a_EW/"+lines+"Mg12a_FWHM*0.9394372787");
  set_par_fun(lines+"Mg12b_A", lines+"Mg12b_EW/"+lines+"Mg12b_FWHM*0.9394372787");
  set_par_fun(lines+"Mg12g_A", lines+"Mg12g_EW/"+lines+"Mg12g_FWHM*0.9394372787");
  set_par_fun(lines+"Mg12d_A", lines+"Mg12d_EW/"+lines+"Mg12d_FWHM*0.9394372787");
  set_par_fun(lines+"Mg11f_A", lines+"Mg11f_EW/"+lines+"Mg11f_FWHM*0.9394372787");
  set_par_fun(lines+"Mg11i_A", lines+"Mg11i_EW/"+lines+"Mg11i_FWHM*0.9394372787");
  set_par_fun(lines+"Mg11a_A", lines+"Mg11a_EW/"+lines+"Mg11a_FWHM*0.9394372787");
  set_par_fun(lines+"Mg11b_A", lines+"Mg11b_EW/"+lines+"Mg11b_FWHM*0.9394372787");
  set_par_fun(lines+"Mg11g_A", lines+"Mg11g_EW/"+lines+"Mg11g_FWHM*0.9394372787");
  set_par_fun(lines+"Mg11d_A", lines+"Mg11d_EW/"+lines+"Mg11d_FWHM*0.9394372787");
  set_par_fun(lines+"Al13a_A", lines+"Al13a_EW/"+lines+"Al13a_FWHM*0.9394372787");
  set_par_fun(lines+"Al13b_A", lines+"Al13b_EW/"+lines+"Al13b_FWHM*0.9394372787");
  set_par_fun(lines+"Al13g_A", lines+"Al13g_EW/"+lines+"Al13g_FWHM*0.9394372787");
  set_par_fun(lines+"Al13d_A", lines+"Al13d_EW/"+lines+"Al13d_FWHM*0.9394372787");
  set_par_fun(lines+"Al12f_A", lines+"Al12f_EW/"+lines+"Al12f_FWHM*0.9394372787");
  set_par_fun(lines+"Al12i_A", lines+"Al12i_EW/"+lines+"Al12i_FWHM*0.9394372787");
  set_par_fun(lines+"Al12a_A", lines+"Al12a_EW/"+lines+"Al12a_FWHM*0.9394372787");
  set_par_fun(lines+"Al12b_A", lines+"Al12b_EW/"+lines+"Al12b_FWHM*0.9394372787");
  set_par_fun(lines+"Al12g_A", lines+"Al12g_EW/"+lines+"Al12g_FWHM*0.9394372787");
  set_par_fun(lines+"Al12d_A", lines+"Al12d_EW/"+lines+"Al12d_FWHM*0.9394372787");
  set_par_fun(lines+"Si14a_A", lines+"Si14a_EW/"+lines+"Si14a_FWHM*0.9394372787");
  set_par_fun(lines+"Si14b_A", lines+"Si14b_EW/"+lines+"Si14b_FWHM*0.9394372787");
  set_par_fun(lines+"Si14g_A", lines+"Si14g_EW/"+lines+"Si14g_FWHM*0.9394372787");
  set_par_fun(lines+"Si14d_A", lines+"Si14d_EW/"+lines+"Si14d_FWHM*0.9394372787");
  set_par_fun(lines+"Si13f_A", lines+"Si13f_EW/"+lines+"Si13f_FWHM*0.9394372787");
  set_par_fun(lines+"Si13i_A", lines+"Si13i_EW/"+lines+"Si13i_FWHM*0.9394372787");
  set_par_fun(lines+"Si13a_A", lines+"Si13a_EW/"+lines+"Si13a_FWHM*0.9394372787");
  set_par_fun(lines+"Si13b_A", lines+"Si13b_EW/"+lines+"Si13b_FWHM*0.9394372787");
  set_par_fun(lines+"Si13g_A", lines+"Si13g_EW/"+lines+"Si13g_FWHM*0.9394372787");
  set_par_fun(lines+"Si13d_A", lines+"Si13d_EW/"+lines+"Si13d_FWHM*0.9394372787");
  set_par_fun(lines+"S16a_A", lines+"S16a_EW/"+lines+"S16a_FWHM*0.9394372787");
  set_par_fun(lines+"S16b_A", lines+"S16b_EW/"+lines+"S16b_FWHM*0.9394372787");
  set_par_fun(lines+"S16g_A", lines+"S16g_EW/"+lines+"S16g_FWHM*0.9394372787");
  set_par_fun(lines+"S16d_A", lines+"S16d_EW/"+lines+"S16d_FWHM*0.9394372787");
  set_par_fun(lines+"S15f_A", lines+"S15f_EW/"+lines+"S15f_FWHM*0.9394372787");
  set_par_fun(lines+"S15i_A", lines+"S15i_EW/"+lines+"S15i_FWHM*0.9394372787");
  set_par_fun(lines+"S15a_A", lines+"S15a_EW/"+lines+"S15a_FWHM*0.9394372787");
  set_par_fun(lines+"S15b_A", lines+"S15b_EW/"+lines+"S15b_FWHM*0.9394372787");
  set_par_fun(lines+"S15g_A", lines+"S15g_EW/"+lines+"S15g_FWHM*0.9394372787");
  set_par_fun(lines+"S15d_A", lines+"S15d_EW/"+lines+"S15d_FWHM*0.9394372787");
  set_par_fun(lines+"Ar18a_A", lines+"Ar18a_EW/"+lines+"Ar18a_FWHM*0.9394372787");
  set_par_fun(lines+"Ar18b_A", lines+"Ar18b_EW/"+lines+"Ar18b_FWHM*0.9394372787");
  set_par_fun(lines+"Ar18g_A", lines+"Ar18g_EW/"+lines+"Ar18g_FWHM*0.9394372787");
  set_par_fun(lines+"Ar18d_A", lines+"Ar18d_EW/"+lines+"Ar18d_FWHM*0.9394372787");
  set_par_fun(lines+"Ar17f_A", lines+"Ar17f_EW/"+lines+"Ar17f_FWHM*0.9394372787");
  set_par_fun(lines+"Ar17i_A", lines+"Ar17i_EW/"+lines+"Ar17i_FWHM*0.9394372787");
  set_par_fun(lines+"Ar17a_A", lines+"Ar17a_EW/"+lines+"Ar17a_FWHM*0.9394372787");
  set_par_fun(lines+"Ar17b_A", lines+"Ar17b_EW/"+lines+"Ar17b_FWHM*0.9394372787");
  set_par_fun(lines+"Ar17g_A", lines+"Ar17g_EW/"+lines+"Ar17g_FWHM*0.9394372787");
  set_par_fun(lines+"Ar17d_A", lines+"Ar17d_EW/"+lines+"Ar17d_FWHM*0.9394372787");
  set_par_fun(lines+"Ca20a_A", lines+"Ca20a_EW/"+lines+"Ca20a_FWHM*0.9394372787");
  set_par_fun(lines+"Ca20b_A", lines+"Ca20b_EW/"+lines+"Ca20b_FWHM*0.9394372787");
  set_par_fun(lines+"Ca20g_A", lines+"Ca20g_EW/"+lines+"Ca20g_FWHM*0.9394372787");
  set_par_fun(lines+"Ca20d_A", lines+"Ca20d_EW/"+lines+"Ca20d_FWHM*0.9394372787");
  set_par_fun(lines+"Ca19f_A", lines+"Ca19f_EW/"+lines+"Ca19f_FWHM*0.9394372787");
  set_par_fun(lines+"Ca19i_A", lines+"Ca19i_EW/"+lines+"Ca19i_FWHM*0.9394372787");
  set_par_fun(lines+"Ca19a_A", lines+"Ca19a_EW/"+lines+"Ca19a_FWHM*0.9394372787");
  set_par_fun(lines+"Ca19b_A", lines+"Ca19b_EW/"+lines+"Ca19b_FWHM*0.9394372787");
  set_par_fun(lines+"Ca19g_A", lines+"Ca19g_EW/"+lines+"Ca19g_FWHM*0.9394372787");
  set_par_fun(lines+"Ca19d_A", lines+"Ca19d_EW/"+lines+"Ca19d_FWHM*0.9394372787");
  set_par_fun(lines+"Fe26a_A", lines+"Fe26a_EW/"+lines+"Fe26a_FWHM*0.9394372787");
  set_par_fun(lines+"Fe26b_A", lines+"Fe26b_EW/"+lines+"Fe26b_FWHM*0.9394372787");
  set_par_fun(lines+"Fe26g_A", lines+"Fe26g_EW/"+lines+"Fe26g_FWHM*0.9394372787");
  set_par_fun(lines+"Fe26d_A", lines+"Fe26d_EW/"+lines+"Fe26d_FWHM*0.9394372787");
  set_par_fun(lines+"Fe25f_A", lines+"Fe25f_EW/"+lines+"Fe25f_FWHM*0.9394372787");
  set_par_fun(lines+"Fe25i_A", lines+"Fe25i_EW/"+lines+"Fe25i_FWHM*0.9394372787");
  set_par_fun(lines+"Fe25a_A", lines+"Fe25a_EW/"+lines+"Fe25a_FWHM*0.9394372787");
  set_par_fun(lines+"Fe25b_A", lines+"Fe25b_EW/"+lines+"Fe25b_FWHM*0.9394372787");
  set_par_fun(lines+"Fe25g_A", lines+"Fe25g_EW/"+lines+"Fe25g_FWHM*0.9394372787");
  set_par_fun(lines+"Fe25d_A", lines+"Fe25d_EW/"+lines+"Fe25d_FWHM*0.9394372787");
  set_par_fun(lines+"Fe1Ka_A", lines+"Fe1Ka_EW/"+lines+"Fe1Ka_FWHM*0.9394372787");
  set_par_fun(lines+"Fe24_1062A_A", lines+"Fe24_1062A_EW/"+lines+"Fe24_1062A_FWHM*0.9394372787");
  set_par_fun(lines+"Fe24_679A_A", lines+"Fe24_679A_EW/"+lines+"Fe24_679A_FWHM*0.9394372787");
  set_par_fun(lines+"bl_1066A_A", lines+"bl_1066A_EW/"+lines+"bl_1066A_FWHM*0.9394372787");
  set_par_fun(lines+"Fe24_799A_A", lines+"Fe24_799A_EW/"+lines+"Fe24_799A_FWHM*0.9394372787");
  set_par_fun(lines+"bl_1102A_A", lines+"bl_1102A_EW/"+lines+"bl_1102A_FWHM*0.9394372787");
  set_par_fun(lines+"bl_1099A_A", lines+"bl_1099A_EW/"+lines+"bl_1099A_FWHM*0.9394372787");
  set_par_fun(lines+"Fe23_830A_A", lines+"Fe23_830A_EW/"+lines+"Fe23_830A_FWHM*0.9394372787");
  set_par_fun(lines+"Fe22_1225A_A", lines+"Fe22_1225A_EW/"+lines+"Fe22_1225A_FWHM*0.9394372787");
  set_par_fun(lines+"Fe22_1143A_A", lines+"Fe22_1143A_EW/"+lines+"Fe22_1143A_FWHM*0.9394372787");
  set_par_fun(lines+"Fe22_897A_A", lines+"Fe22_897A_EW/"+lines+"Fe22_897A_FWHM*0.9394372787");
  set_par_fun(lines+"Fe22_1193A_A", lines+"Fe22_1193A_EW/"+lines+"Fe22_1193A_FWHM*0.9394372787");
  set_par_fun(lines+"bl_1177A_A", lines+"bl_1177A_EW/"+lines+"bl_1177A_FWHM*0.9394372787");
  set_par_fun(lines+"Fe22_1149A_A", lines+"Fe22_1149A_EW/"+lines+"Fe22_1149A_FWHM*0.9394372787");
  set_par_fun(lines+"Fe22_873A_A", lines+"Fe22_873A_EW/"+lines+"Fe22_873A_FWHM*0.9394372787");
  set_par_fun(lines+"Fe22_786A_A", lines+"Fe22_786A_EW/"+lines+"Fe22_786A_FWHM*0.9394372787");
  set_par_fun(lines+"Fe21_1228A_A", lines+"Fe21_1228A_EW/"+lines+"Fe21_1228A_FWHM*0.9394372787");
  set_par_fun(lines+"Fe21_1198A_A", lines+"Fe21_1198A_EW/"+lines+"Fe21_1198A_FWHM*0.9394372787");
  set_par_fun(lines+"Fe21_1304A_A", lines+"Fe21_1304A_EW/"+lines+"Fe21_1304A_FWHM*0.9394372787");
  set_par_fun(lines+"bl_920A_A", lines+"bl_920A_EW/"+lines+"bl_920A_FWHM*0.9394372787");
  set_par_fun(lines+"Fe21_857A_A", lines+"Fe21_857A_EW/"+lines+"Fe21_857A_FWHM*0.9394372787");
  set_par_fun(lines+"Fe21_1233A_A", lines+"Fe21_1233A_EW/"+lines+"Fe21_1233A_FWHM*0.9394372787");
  set_par_fun(lines+"Fe20_1292A_A", lines+"Fe20_1292A_EW/"+lines+"Fe20_1292A_FWHM*0.9394372787");
  set_par_fun(lines+"Fe20_1286A_A", lines+"Fe20_1286A_EW/"+lines+"Fe20_1286A_FWHM*0.9394372787");
  set_par_fun(lines+"Fe20_1283A_A", lines+"Fe20_1283A_EW/"+lines+"Fe20_1283A_FWHM*0.9394372787");
  set_par_fun(lines+"Fe20_1258A_A", lines+"Fe20_1258A_EW/"+lines+"Fe20_1258A_FWHM*0.9394372787");
  set_par_fun(lines+"Fe20_1000A_A", lines+"Fe20_1000A_EW/"+lines+"Fe20_1000A_FWHM*0.9394372787");
  set_par_fun(lines+"Fe20_1297A_A", lines+"Fe20_1297A_EW/"+lines+"Fe20_1297A_FWHM*0.9394372787");
  set_par_fun(lines+"bl_1012A_A", lines+"bl_1012A_EW/"+lines+"bl_1012A_FWHM*0.9394372787");
  set_par_fun(lines+"bl_1301A_A", lines+"bl_1301A_EW/"+lines+"bl_1301A_FWHM*0.9394372787");
  set_par_fun(lines+"Fe19_1466A_A", lines+"Fe19_1466A_EW/"+lines+"Fe19_1466A_FWHM*0.9394372787");
  set_par_fun(lines+"Fe19_1380A_A", lines+"Fe19_1380A_EW/"+lines+"Fe19_1380A_FWHM*0.9394372787");
  set_par_fun(lines+"Fe19_1364A_A", lines+"Fe19_1364A_EW/"+lines+"Fe19_1364A_FWHM*0.9394372787");
  set_par_fun(lines+"Fe19_1350A_A", lines+"Fe19_1350A_EW/"+lines+"Fe19_1350A_FWHM*0.9394372787");
  set_par_fun(lines+"Fe19_1346A_A", lines+"Fe19_1346A_EW/"+lines+"Fe19_1346A_FWHM*0.9394372787");
  set_par_fun(lines+"Fe19_1342A_A", lines+"Fe19_1342A_EW/"+lines+"Fe19_1342A_FWHM*0.9394372787");
  set_par_fun(lines+"Fe19_1294A_A", lines+"Fe19_1294A_EW/"+lines+"Fe19_1294A_FWHM*0.9394372787");
  set_par_fun(lines+"Fe19_1082A_A", lines+"Fe19_1082A_EW/"+lines+"Fe19_1082A_FWHM*0.9394372787");
  set_par_fun(lines+"Fe19_1013A_A", lines+"Fe19_1013A_EW/"+lines+"Fe19_1013A_FWHM*0.9394372787");
  set_par_fun(lines+"Fe19_986A_A", lines+"Fe19_986A_EW/"+lines+"Fe19_986A_FWHM*0.9394372787");
  set_par_fun(lines+"Fe19_1352A_A", lines+"Fe19_1352A_EW/"+lines+"Fe19_1352A_FWHM*0.9394372787");
  set_par_fun(lines+"Fe19_1293A_A", lines+"Fe19_1293A_EW/"+lines+"Fe19_1293A_FWHM*0.9394372787");
  set_par_fun(lines+"Fe18_1453A_A", lines+"Fe18_1453A_EW/"+lines+"Fe18_1453A_FWHM*0.9394372787");
  set_par_fun(lines+"Fe18_1437A_A", lines+"Fe18_1437A_EW/"+lines+"Fe18_1437A_FWHM*0.9394372787");
  set_par_fun(lines+"Fe18_1457A_A", lines+"Fe18_1457A_EW/"+lines+"Fe18_1457A_FWHM*0.9394372787");
  set_par_fun(lines+"Fe18_1562A_A", lines+"Fe18_1562A_EW/"+lines+"Fe18_1562A_FWHM*0.9394372787");
  set_par_fun(lines+"Fe18_1332A_A", lines+"Fe18_1332A_EW/"+lines+"Fe18_1332A_FWHM*0.9394372787");
  set_par_fun(lines+"Fe18_1426A_A", lines+"Fe18_1426A_EW/"+lines+"Fe18_1426A_FWHM*0.9394372787");
  set_par_fun(lines+"Fe18_1421A_A", lines+"Fe18_1421A_EW/"+lines+"Fe18_1421A_FWHM*0.9394372787");
  set_par_fun(lines+"Fe18_1153A_A", lines+"Fe18_1153A_EW/"+lines+"Fe18_1153A_FWHM*0.9394372787");
  set_par_fun(lines+"Fe18_1133A_A", lines+"Fe18_1133A_EW/"+lines+"Fe18_1133A_FWHM*0.9394372787");
  set_par_fun(lines+"Fe17_1678A_A", lines+"Fe17_1678A_EW/"+lines+"Fe17_1678A_FWHM*0.9394372787");
  set_par_fun(lines+"Fe17_1526A_A", lines+"Fe17_1526A_EW/"+lines+"Fe17_1526A_FWHM*0.9394372787");
  set_par_fun(lines+"Fe17_1501A_A", lines+"Fe17_1501A_EW/"+lines+"Fe17_1501A_FWHM*0.9394372787");
  set_par_fun(lines+"Fe17_1227A_A", lines+"Fe17_1227A_EW/"+lines+"Fe17_1227A_FWHM*0.9394372787");
  set_par_fun(lines+"Fe17_1212A_A", lines+"Fe17_1212A_EW/"+lines+"Fe17_1212A_FWHM*0.9394372787");
  set_par_fun(lines+"Fe17_1536A_A", lines+"Fe17_1536A_EW/"+lines+"Fe17_1536A_FWHM*0.9394372787");
  set_par_fun(lines+"Fe17_1382A_A", lines+"Fe17_1382A_EW/"+lines+"Fe17_1382A_FWHM*0.9394372787");
  set_par_fun(lines+"bl_1384A_A", lines+"bl_1384A_EW/"+lines+"bl_1384A_FWHM*0.9394372787");
  set_par_fun(lines+"Al11Ka_A", lines+"Al11Ka_EW/"+lines+"Al11Ka_FWHM*0.9394372787");
  set_par_fun(lines+"Al10Ka_A", lines+"Al10Ka_EW/"+lines+"Al10Ka_FWHM*0.9394372787");
  set_par_fun(lines+"Al9Ka_A", lines+"Al9Ka_EW/"+lines+"Al9Ka_FWHM*0.9394372787");
  set_par_fun(lines+"Al8Ka_A", lines+"Al8Ka_EW/"+lines+"Al8Ka_FWHM*0.9394372787");
  set_par_fun(lines+"Al7Ka_A", lines+"Al7Ka_EW/"+lines+"Al7Ka_FWHM*0.9394372787");
  set_par_fun(lines+"Al6Ka_A", lines+"Al6Ka_EW/"+lines+"Al6Ka_FWHM*0.9394372787");
  set_par_fun(lines+"Al5Ka_A", lines+"Al5Ka_EW/"+lines+"Al5Ka_FWHM*0.9394372787");
  set_par_fun(lines+"Al4Ka_A", lines+"Al4Ka_EW/"+lines+"Al4Ka_FWHM*0.9394372787");
  set_par_fun(lines+"Al3Ka_A", lines+"Al3Ka_EW/"+lines+"Al3Ka_FWHM*0.9394372787");
  set_par_fun(lines+"Al2Ka_A", lines+"Al2Ka_EW/"+lines+"Al2Ka_FWHM*0.9394372787");
  set_par_fun(lines+"Si12Ka_A", lines+"Si12Ka_EW/"+lines+"Si12Ka_FWHM*0.9394372787");
  set_par_fun(lines+"Si11Ka_A", lines+"Si11Ka_EW/"+lines+"Si11Ka_FWHM*0.9394372787");
  set_par_fun(lines+"Si10Ka_A", lines+"Si10Ka_EW/"+lines+"Si10Ka_FWHM*0.9394372787");
  set_par_fun(lines+"Si9Ka_A", lines+"Si9Ka_EW/"+lines+"Si9Ka_FWHM*0.9394372787");
  set_par_fun(lines+"Si8Ka_A", lines+"Si8Ka_EW/"+lines+"Si8Ka_FWHM*0.9394372787");
  set_par_fun(lines+"Si7Ka_A", lines+"Si7Ka_EW/"+lines+"Si7Ka_FWHM*0.9394372787");
  set_par_fun(lines+"Si6Ka_A", lines+"Si6Ka_EW/"+lines+"Si6Ka_FWHM*0.9394372787");
  set_par_fun(lines+"Si5Ka_A", lines+"Si5Ka_EW/"+lines+"Si5Ka_FWHM*0.9394372787");
  set_par_fun(lines+"Si4Ka_A", lines+"Si4Ka_EW/"+lines+"Si4Ka_FWHM*0.9394372787");
  set_par_fun(lines+"Si3Ka_A", lines+"Si3Ka_EW/"+lines+"Si3Ka_FWHM*0.9394372787");
  set_par_fun(lines+"Si2Ka_A", lines+"Si2Ka_EW/"+lines+"Si2Ka_FWHM*0.9394372787");
  set_par_fun(lines+"Ar16Ka_A", lines+"Ar16Ka_EW/"+lines+"Ar16Ka_FWHM*0.9394372787");
  set_par_fun(lines+"Ar15Ka_A", lines+"Ar15Ka_EW/"+lines+"Ar15Ka_FWHM*0.9394372787");
  set_par_fun(lines+"Ar14Ka_A", lines+"Ar14Ka_EW/"+lines+"Ar14Ka_FWHM*0.9394372787");
  set_par_fun(lines+"Ar13Ka_A", lines+"Ar13Ka_EW/"+lines+"Ar13Ka_FWHM*0.9394372787");
  set_par_fun(lines+"Ar12Ka_A", lines+"Ar12Ka_EW/"+lines+"Ar12Ka_FWHM*0.9394372787");
  set_par_fun(lines+"Ar11Ka_A", lines+"Ar11Ka_EW/"+lines+"Ar11Ka_FWHM*0.9394372787");
  set_par_fun(lines+"Ar10Ka_A", lines+"Ar10Ka_EW/"+lines+"Ar10Ka_FWHM*0.9394372787");
  set_par_fun(lines+"Ar9Ka_A", lines+"Ar9Ka_EW/"+lines+"Ar9Ka_FWHM*0.9394372787");
  set_par_fun(lines+"Ar8Ka_A", lines+"Ar8Ka_EW/"+lines+"Ar8Ka_FWHM*0.9394372787");
  set_par_fun(lines+"Ar7Ka_A", lines+"Ar7Ka_EW/"+lines+"Ar7Ka_FWHM*0.9394372787");
  set_par_fun(lines+"Ar6Ka_A", lines+"Ar6Ka_EW/"+lines+"Ar6Ka_FWHM*0.9394372787");
  set_par_fun(lines+"Ar5Ka_A", lines+"Ar5Ka_EW/"+lines+"Ar5Ka_FWHM*0.9394372787");
  set_par_fun(lines+"Ar4Ka_A", lines+"Ar4Ka_EW/"+lines+"Ar4Ka_FWHM*0.9394372787");
  set_par_fun(lines+"Ar3Ka_A", lines+"Ar3Ka_EW/"+lines+"Ar3Ka_FWHM*0.9394372787");
  set_par_fun(lines+"Ar2Ka_A", lines+"Ar2Ka_EW/"+lines+"Ar2Ka_FWHM*0.9394372787");
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define unset_lines_par_fun()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{unset_lines_par_fun}
%\synopsis{removes the par_fun's in a lines-model to speed up the model}
%\usage{unset_lines_par_fun([Integer_Type id]);}
%\description
%    The amplitude parameters of the lines-model are reset for every line:\n
%    \code{set_par_fun("lines(id).line_A", NULL);}\n
%    If \code{id} is not specified, code{id=1} is used.
%\seealso{gauss, lines, set_lines_par_fun}
%!%-
{
  variable id=1;
  switch(_NARGS)
  { case 0: ; }
  { case 1: id = (); }
  { help(_function_name()); return; }

  variable lines = "lines("+string(id)+").";
  set_par_fun(lines+"O8a_A", NULL); freeze(lines+"O8a_A");
  set_par_fun(lines+"O8b_A", NULL); freeze(lines+"O8b_A");
  set_par_fun(lines+"O8g_A", NULL); freeze(lines+"O8g_A");
  set_par_fun(lines+"O8d_A", NULL); freeze(lines+"O8d_A");
  set_par_fun(lines+"O7f_A", NULL); freeze(lines+"O7f_A");
  set_par_fun(lines+"O7i_A", NULL); freeze(lines+"O7i_A");
  set_par_fun(lines+"O7a_A", NULL); freeze(lines+"O7a_A");
  set_par_fun(lines+"O7b_A", NULL); freeze(lines+"O7b_A");
  set_par_fun(lines+"O7g_A", NULL); freeze(lines+"O7g_A");
  set_par_fun(lines+"O7d_A", NULL); freeze(lines+"O7d_A");
  set_par_fun(lines+"Ne10a_A", NULL); freeze(lines+"Ne10a_A");
  set_par_fun(lines+"Ne10b_A", NULL); freeze(lines+"Ne10b_A");
  set_par_fun(lines+"Ne10g_A", NULL); freeze(lines+"Ne10g_A");
  set_par_fun(lines+"Ne10d_A", NULL); freeze(lines+"Ne10d_A");
  set_par_fun(lines+"Ne10e_A", NULL); freeze(lines+"Ne10e_A");
  set_par_fun(lines+"Ne10z_A", NULL); freeze(lines+"Ne10z_A");
  set_par_fun(lines+"Ne9f_A", NULL); freeze(lines+"Ne9f_A");
  set_par_fun(lines+"Ne9i_A", NULL); freeze(lines+"Ne9i_A");
  set_par_fun(lines+"Ne9a_A", NULL); freeze(lines+"Ne9a_A");
  set_par_fun(lines+"Ne9b_A", NULL); freeze(lines+"Ne9b_A");
  set_par_fun(lines+"Ne9g_A", NULL); freeze(lines+"Ne9g_A");
  set_par_fun(lines+"Ne9d_A", NULL); freeze(lines+"Ne9d_A");
  set_par_fun(lines+"Ne9e_A", NULL); freeze(lines+"Ne9e_A");
  set_par_fun(lines+"Ne9z_A", NULL); freeze(lines+"Ne9z_A");
  set_par_fun(lines+"Na11a_A", NULL); freeze(lines+"Na11a_A");
  set_par_fun(lines+"Na11b_A", NULL); freeze(lines+"Na11b_A");
  set_par_fun(lines+"Na11g_A", NULL); freeze(lines+"Na11g_A");
  set_par_fun(lines+"Na11d_A", NULL); freeze(lines+"Na11d_A");
  set_par_fun(lines+"Na10f_A", NULL); freeze(lines+"Na10f_A");
  set_par_fun(lines+"Na10i_A", NULL); freeze(lines+"Na10i_A");
  set_par_fun(lines+"Na10a_A", NULL); freeze(lines+"Na10a_A");
  set_par_fun(lines+"Na10b_A", NULL); freeze(lines+"Na10b_A");
  set_par_fun(lines+"Na10g_A", NULL); freeze(lines+"Na10g_A");
  set_par_fun(lines+"Na10d_A", NULL); freeze(lines+"Na10d_A");
  set_par_fun(lines+"Mg12a_A", NULL); freeze(lines+"Mg12a_A");
  set_par_fun(lines+"Mg12b_A", NULL); freeze(lines+"Mg12b_A");
  set_par_fun(lines+"Mg12g_A", NULL); freeze(lines+"Mg12g_A");
  set_par_fun(lines+"Mg12d_A", NULL); freeze(lines+"Mg12d_A");
  set_par_fun(lines+"Mg11f_A", NULL); freeze(lines+"Mg11f_A");
  set_par_fun(lines+"Mg11i_A", NULL); freeze(lines+"Mg11i_A");
  set_par_fun(lines+"Mg11a_A", NULL); freeze(lines+"Mg11a_A");
  set_par_fun(lines+"Mg11b_A", NULL); freeze(lines+"Mg11b_A");
  set_par_fun(lines+"Mg11g_A", NULL); freeze(lines+"Mg11g_A");
  set_par_fun(lines+"Mg11d_A", NULL); freeze(lines+"Mg11d_A");
  set_par_fun(lines+"Al13a_A", NULL); freeze(lines+"Al13a_A");
  set_par_fun(lines+"Al13b_A", NULL); freeze(lines+"Al13b_A");
  set_par_fun(lines+"Al13g_A", NULL); freeze(lines+"Al13g_A");
  set_par_fun(lines+"Al13d_A", NULL); freeze(lines+"Al13d_A");
  set_par_fun(lines+"Al12f_A", NULL); freeze(lines+"Al12f_A");
  set_par_fun(lines+"Al12i_A", NULL); freeze(lines+"Al12i_A");
  set_par_fun(lines+"Al12a_A", NULL); freeze(lines+"Al12a_A");
  set_par_fun(lines+"Al12b_A", NULL); freeze(lines+"Al12b_A");
  set_par_fun(lines+"Al12g_A", NULL); freeze(lines+"Al12g_A");
  set_par_fun(lines+"Al12d_A", NULL); freeze(lines+"Al12d_A");
  set_par_fun(lines+"Si14a_A", NULL); freeze(lines+"Si14a_A");
  set_par_fun(lines+"Si14b_A", NULL); freeze(lines+"Si14b_A");
  set_par_fun(lines+"Si14g_A", NULL); freeze(lines+"Si14g_A");
  set_par_fun(lines+"Si14d_A", NULL); freeze(lines+"Si14d_A");
  set_par_fun(lines+"Si13f_A", NULL); freeze(lines+"Si13f_A");
  set_par_fun(lines+"Si13i_A", NULL); freeze(lines+"Si13i_A");
  set_par_fun(lines+"Si13a_A", NULL); freeze(lines+"Si13a_A");
  set_par_fun(lines+"Si13b_A", NULL); freeze(lines+"Si13b_A");
  set_par_fun(lines+"Si13g_A", NULL); freeze(lines+"Si13g_A");
  set_par_fun(lines+"Si13d_A", NULL); freeze(lines+"Si13d_A");
  set_par_fun(lines+"S16a_A", NULL); freeze(lines+"S16a_A");
  set_par_fun(lines+"S16b_A", NULL); freeze(lines+"S16b_A");
  set_par_fun(lines+"S16g_A", NULL); freeze(lines+"S16g_A");
  set_par_fun(lines+"S16d_A", NULL); freeze(lines+"S16d_A");
  set_par_fun(lines+"S15f_A", NULL); freeze(lines+"S15f_A");
  set_par_fun(lines+"S15i_A", NULL); freeze(lines+"S15i_A");
  set_par_fun(lines+"S15a_A", NULL); freeze(lines+"S15a_A");
  set_par_fun(lines+"S15b_A", NULL); freeze(lines+"S15b_A");
  set_par_fun(lines+"S15g_A", NULL); freeze(lines+"S15g_A");
  set_par_fun(lines+"S15d_A", NULL); freeze(lines+"S15d_A");
  set_par_fun(lines+"Ar18a_A", NULL); freeze(lines+"Ar18a_A");
  set_par_fun(lines+"Ar18b_A", NULL); freeze(lines+"Ar18b_A");
  set_par_fun(lines+"Ar18g_A", NULL); freeze(lines+"Ar18g_A");
  set_par_fun(lines+"Ar18d_A", NULL); freeze(lines+"Ar18d_A");
  set_par_fun(lines+"Ar17f_A", NULL); freeze(lines+"Ar17f_A");
  set_par_fun(lines+"Ar17i_A", NULL); freeze(lines+"Ar17i_A");
  set_par_fun(lines+"Ar17a_A", NULL); freeze(lines+"Ar17a_A");
  set_par_fun(lines+"Ar17b_A", NULL); freeze(lines+"Ar17b_A");
  set_par_fun(lines+"Ar17g_A", NULL); freeze(lines+"Ar17g_A");
  set_par_fun(lines+"Ar17d_A", NULL); freeze(lines+"Ar17d_A");
  set_par_fun(lines+"Ca20a_A", NULL); freeze(lines+"Ca20a_A");
  set_par_fun(lines+"Ca20b_A", NULL); freeze(lines+"Ca20b_A");
  set_par_fun(lines+"Ca20g_A", NULL); freeze(lines+"Ca20g_A");
  set_par_fun(lines+"Ca20d_A", NULL); freeze(lines+"Ca20d_A");
  set_par_fun(lines+"Ca19f_A", NULL); freeze(lines+"Ca19f_A");
  set_par_fun(lines+"Ca19i_A", NULL); freeze(lines+"Ca19i_A");
  set_par_fun(lines+"Ca19a_A", NULL); freeze(lines+"Ca19a_A");
  set_par_fun(lines+"Ca19b_A", NULL); freeze(lines+"Ca19b_A");
  set_par_fun(lines+"Ca19g_A", NULL); freeze(lines+"Ca19g_A");
  set_par_fun(lines+"Ca19d_A", NULL); freeze(lines+"Ca19d_A");
  set_par_fun(lines+"Fe26a_A", NULL); freeze(lines+"Fe26a_A");
  set_par_fun(lines+"Fe26b_A", NULL); freeze(lines+"Fe26b_A");
  set_par_fun(lines+"Fe26g_A", NULL); freeze(lines+"Fe26g_A");
  set_par_fun(lines+"Fe26d_A", NULL); freeze(lines+"Fe26d_A");
  set_par_fun(lines+"Fe25f_A", NULL); freeze(lines+"Fe25f_A");
  set_par_fun(lines+"Fe25i_A", NULL); freeze(lines+"Fe25i_A");
  set_par_fun(lines+"Fe25a_A", NULL); freeze(lines+"Fe25a_A");
  set_par_fun(lines+"Fe25b_A", NULL); freeze(lines+"Fe25b_A");
  set_par_fun(lines+"Fe25g_A", NULL); freeze(lines+"Fe25g_A");
  set_par_fun(lines+"Fe25d_A", NULL); freeze(lines+"Fe25d_A");
  set_par_fun(lines+"Fe1Ka_A", NULL); freeze(lines+"Fe1Ka_A");
  set_par_fun(lines+"Fe24_1062A_A", NULL); freeze(lines+"Fe24_1062A_A");
  set_par_fun(lines+"Fe24_679A_A", NULL); freeze(lines+"Fe24_679A_A");
  set_par_fun(lines+"bl_1066A_A", NULL); freeze(lines+"bl_1066A_A");
  set_par_fun(lines+"Fe24_799A_A", NULL); freeze(lines+"Fe24_799A_A");
  set_par_fun(lines+"bl_1102A_A", NULL); freeze(lines+"bl_1102A_A");
  set_par_fun(lines+"bl_1099A_A", NULL); freeze(lines+"bl_1099A_A");
  set_par_fun(lines+"Fe23_830A_A", NULL); freeze(lines+"Fe23_830A_A");
  set_par_fun(lines+"Fe22_1225A_A", NULL); freeze(lines+"Fe22_1225A_A");
  set_par_fun(lines+"Fe22_1143A_A", NULL); freeze(lines+"Fe22_1143A_A");
  set_par_fun(lines+"Fe22_897A_A", NULL); freeze(lines+"Fe22_897A_A");
  set_par_fun(lines+"Fe22_1193A_A", NULL); freeze(lines+"Fe22_1193A_A");
  set_par_fun(lines+"bl_1177A_A", NULL); freeze(lines+"bl_1177A_A");
  set_par_fun(lines+"Fe22_1149A_A", NULL); freeze(lines+"Fe22_1149A_A");
  set_par_fun(lines+"Fe22_873A_A", NULL); freeze(lines+"Fe22_873A_A");
  set_par_fun(lines+"Fe22_786A_A", NULL); freeze(lines+"Fe22_786A_A");
  set_par_fun(lines+"Fe21_1228A_A", NULL); freeze(lines+"Fe21_1228A_A");
  set_par_fun(lines+"Fe21_1198A_A", NULL); freeze(lines+"Fe21_1198A_A");
  set_par_fun(lines+"Fe21_1304A_A", NULL); freeze(lines+"Fe21_1304A_A");
  set_par_fun(lines+"bl_920A_A", NULL); freeze(lines+"bl_920A_A");
  set_par_fun(lines+"Fe21_857A_A", NULL); freeze(lines+"Fe21_857A_A");
  set_par_fun(lines+"Fe21_1233A_A", NULL); freeze(lines+"Fe21_1233A_A");
  set_par_fun(lines+"Fe20_1292A_A", NULL); freeze(lines+"Fe20_1292A_A");
  set_par_fun(lines+"Fe20_1286A_A", NULL); freeze(lines+"Fe20_1286A_A");
  set_par_fun(lines+"Fe20_1283A_A", NULL); freeze(lines+"Fe20_1283A_A");
  set_par_fun(lines+"Fe20_1258A_A", NULL); freeze(lines+"Fe20_1258A_A");
  set_par_fun(lines+"Fe20_1000A_A", NULL); freeze(lines+"Fe20_1000A_A");
  set_par_fun(lines+"Fe20_1297A_A", NULL); freeze(lines+"Fe20_1297A_A");
  set_par_fun(lines+"bl_1012A_A", NULL); freeze(lines+"bl_1012A_A");
  set_par_fun(lines+"bl_1301A_A", NULL); freeze(lines+"bl_1301A_A");
  set_par_fun(lines+"Fe19_1466A_A", NULL); freeze(lines+"Fe19_1466A_A");
  set_par_fun(lines+"Fe19_1380A_A", NULL); freeze(lines+"Fe19_1380A_A");
  set_par_fun(lines+"Fe19_1364A_A", NULL); freeze(lines+"Fe19_1364A_A");
  set_par_fun(lines+"Fe19_1350A_A", NULL); freeze(lines+"Fe19_1350A_A");
  set_par_fun(lines+"Fe19_1346A_A", NULL); freeze(lines+"Fe19_1346A_A");
  set_par_fun(lines+"Fe19_1342A_A", NULL); freeze(lines+"Fe19_1342A_A");
  set_par_fun(lines+"Fe19_1294A_A", NULL); freeze(lines+"Fe19_1294A_A");
  set_par_fun(lines+"Fe19_1082A_A", NULL); freeze(lines+"Fe19_1082A_A");
  set_par_fun(lines+"Fe19_1013A_A", NULL); freeze(lines+"Fe19_1013A_A");
  set_par_fun(lines+"Fe19_986A_A", NULL); freeze(lines+"Fe19_986A_A");
  set_par_fun(lines+"Fe19_1352A_A", NULL); freeze(lines+"Fe19_1352A_A");
  set_par_fun(lines+"Fe19_1293A_A", NULL); freeze(lines+"Fe19_1293A_A");
  set_par_fun(lines+"Fe18_1453A_A", NULL); freeze(lines+"Fe18_1453A_A");
  set_par_fun(lines+"Fe18_1437A_A", NULL); freeze(lines+"Fe18_1437A_A");
  set_par_fun(lines+"Fe18_1457A_A", NULL); freeze(lines+"Fe18_1457A_A");
  set_par_fun(lines+"Fe18_1562A_A", NULL); freeze(lines+"Fe18_1562A_A");
  set_par_fun(lines+"Fe18_1332A_A", NULL); freeze(lines+"Fe18_1332A_A");
  set_par_fun(lines+"Fe18_1426A_A", NULL); freeze(lines+"Fe18_1426A_A");
  set_par_fun(lines+"Fe18_1421A_A", NULL); freeze(lines+"Fe18_1421A_A");
  set_par_fun(lines+"Fe18_1153A_A", NULL); freeze(lines+"Fe18_1153A_A");
  set_par_fun(lines+"Fe18_1133A_A", NULL); freeze(lines+"Fe18_1133A_A");
  set_par_fun(lines+"Fe17_1678A_A", NULL); freeze(lines+"Fe17_1678A_A");
  set_par_fun(lines+"Fe17_1526A_A", NULL); freeze(lines+"Fe17_1526A_A");
  set_par_fun(lines+"Fe17_1501A_A", NULL); freeze(lines+"Fe17_1501A_A");
  set_par_fun(lines+"Fe17_1227A_A", NULL); freeze(lines+"Fe17_1227A_A");
  set_par_fun(lines+"Fe17_1212A_A", NULL); freeze(lines+"Fe17_1212A_A");
  set_par_fun(lines+"Fe17_1536A_A", NULL); freeze(lines+"Fe17_1536A_A");
  set_par_fun(lines+"Fe17_1382A_A", NULL); freeze(lines+"Fe17_1382A_A");
  set_par_fun(lines+"bl_1384A_A", NULL); freeze(lines+"bl_1384A_A");
  set_par_fun(lines+"Al11Ka_A", NULL); freeze(lines+"Al11Ka_A");
  set_par_fun(lines+"Al10Ka_A", NULL); freeze(lines+"Al10Ka_A");
  set_par_fun(lines+"Al9Ka_A", NULL); freeze(lines+"Al9Ka_A");
  set_par_fun(lines+"Al8Ka_A", NULL); freeze(lines+"Al8Ka_A");
  set_par_fun(lines+"Al7Ka_A", NULL); freeze(lines+"Al7Ka_A");
  set_par_fun(lines+"Al6Ka_A", NULL); freeze(lines+"Al6Ka_A");
  set_par_fun(lines+"Al5Ka_A", NULL); freeze(lines+"Al5Ka_A");
  set_par_fun(lines+"Al4Ka_A", NULL); freeze(lines+"Al4Ka_A");
  set_par_fun(lines+"Al3Ka_A", NULL); freeze(lines+"Al3Ka_A");
  set_par_fun(lines+"Al2Ka_A", NULL); freeze(lines+"Al2Ka_A");
  set_par_fun(lines+"Si12Ka_A", NULL); freeze(lines+"Si12Ka_A");
  set_par_fun(lines+"Si11Ka_A", NULL); freeze(lines+"Si11Ka_A");
  set_par_fun(lines+"Si10Ka_A", NULL); freeze(lines+"Si10Ka_A");
  set_par_fun(lines+"Si9Ka_A", NULL); freeze(lines+"Si9Ka_A");
  set_par_fun(lines+"Si8Ka_A", NULL); freeze(lines+"Si8Ka_A");
  set_par_fun(lines+"Si7Ka_A", NULL); freeze(lines+"Si7Ka_A");
  set_par_fun(lines+"Si6Ka_A", NULL); freeze(lines+"Si6Ka_A");
  set_par_fun(lines+"Si5Ka_A", NULL); freeze(lines+"Si5Ka_A");
  set_par_fun(lines+"Si4Ka_A", NULL); freeze(lines+"Si4Ka_A");
  set_par_fun(lines+"Si3Ka_A", NULL); freeze(lines+"Si3Ka_A");
  set_par_fun(lines+"Si2Ka_A", NULL); freeze(lines+"Si2Ka_A");
  set_par_fun(lines+"Ar16Ka_A", NULL); freeze(lines+"Ar16Ka_A");
  set_par_fun(lines+"Ar15Ka_A", NULL); freeze(lines+"Ar15Ka_A");
  set_par_fun(lines+"Ar14Ka_A", NULL); freeze(lines+"Ar14Ka_A");
  set_par_fun(lines+"Ar13Ka_A", NULL); freeze(lines+"Ar13Ka_A");
  set_par_fun(lines+"Ar12Ka_A", NULL); freeze(lines+"Ar12Ka_A");
  set_par_fun(lines+"Ar11Ka_A", NULL); freeze(lines+"Ar11Ka_A");
  set_par_fun(lines+"Ar10Ka_A", NULL); freeze(lines+"Ar10Ka_A");
  set_par_fun(lines+"Ar9Ka_A", NULL); freeze(lines+"Ar9Ka_A");
  set_par_fun(lines+"Ar8Ka_A", NULL); freeze(lines+"Ar8Ka_A");
  set_par_fun(lines+"Ar7Ka_A", NULL); freeze(lines+"Ar7Ka_A");
  set_par_fun(lines+"Ar6Ka_A", NULL); freeze(lines+"Ar6Ka_A");
  set_par_fun(lines+"Ar5Ka_A", NULL); freeze(lines+"Ar5Ka_A");
  set_par_fun(lines+"Ar4Ka_A", NULL); freeze(lines+"Ar4Ka_A");
  set_par_fun(lines+"Ar3Ka_A", NULL); freeze(lines+"Ar3Ka_A");
  set_par_fun(lines+"Ar2Ka_A", NULL); freeze(lines+"Ar2Ka_A");
}


%%%%%%%%%%%%%%%%%%%%%%%%%
define set_gauss_line_par()
%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{set_gauss_line_par}
%\synopsis{initializes a line in the lines-model with the parameters of a gauss-line}
%\usage{set_gauss_line_par([id,] line, area, center, sigma);}
%\description
%    If \code{id} is not specified, \code{id=1} is used.
%    \code{line} is the name in the lines-model, appearing as parameters
%    \code{line_lam}, \code{line_EW}, \code{line_FWHM} and \code{line_A}.
%\seealso{gauss, lines}
%!%-
{
  variable id=1, line, area, center, sigma;
  switch(_NARGS)
  { case 4: (line, area, center, sigma) = (); }
  { case 5: (id, line, area, center, sigma) = (); }
  { help(_function_name()); return; }

  if(line=="") { message(sprintf("warning (%s): line @ %.4f A without a name is skipped", _function_name(), center)); return; }

  line = sprintf("lines(%d).%s_", id, line);
  % message(line);
  if( howmany(array_struct_field(get_params(), "name")==line) == 0 )  { message("error (%s): %s does not exist", _function_name(), line); return; }
  variable info = get_par_info(line+"lam");
  % print(info);
  if(center < info.min or center > info.max)
  { set_par(line+"lam", center, 0, _min(info.min, center), _max(info.max, center));
    message(sprintf("warning (%s): line @ %.2f A is out of range [%.4f:%.4f]", _function_name(), center, info.min, info.max));
  }
  else
  { set_par(line+"lam", center, 0); }
  set_par(line+"EW", abs(area)*1e3, 0);
  variable A = area/sqrt(2*PI)/sigma;
  if(A<-1) { message(sprintf("warning (%s): line @ %.2f A had amplitude %.1f< -1. It is now set to -1.", _function_name(), center, A)); A = -1; }
  if(A>10) { message(sprintf("warning (%s): line @ %.2f A had amplitude %g > 10. It is now set to 10.", _function_name(), center, A)); A = 10; }
  set_par(line+"A", A, 0);
}


%%%%%%%%%%%%%%%
define fit_line()
%%%%%%%%%%%%%%%
%!%+
%\function{fit_line}
%\synopsis{activates a line in the lines model and fits its parameters}
%\usage{fit_line([id,] line);}
%\seealso{lines}
%!%-
{
  variable id=1, line;
  switch(_NARGS)
  { case 1:      line  = (); }
  { case 2: (id, line) = (); }
  { help(_function_name()); return; }

  line = sprintf("lines(%d).%s_", id, line);

  variable t = thawedParameters();
  freeze("*");
  thaw(line+"lam");
  if(get_par(line+"EW")==0)  { set_par(line+"EW", -10, 0); }  else  { thaw(line+"EW"); }
  thaw(line+"FWHM");

  message("before fitting");
  list_free;

  fit_counts;
  message("after fitting");
  list_free;

  thaw(t);
}
%%%%%%%%%%%%%%%%%%%%
define dont_use_line()
%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{dont_use_line}
%\synopsis{sets the EW / amplitude of a line in the lines-model to zero}
%\usage{dont_use_line([id,] line);}
%\description
%    If \code{id} is not specified, \code{id=1} is used.
%    \code{line} is the name in the lines-model, appearing as parameters
%    \code{line_lam}, \code{line_EW}, \code{line_FWHM} and \code{line_A}.
%\seealso{lines}
%!%-
{
  variable id=1, line;
  switch(_NARGS)
  { case 1: (line) = (); }
  { case 2: (id, line) = (); }
  { help(_function_name()); return; }

  variable l;
  foreach l ([line])
  { l = sprintf("lines(%d).%s_", id, l);
    set_par(l+"EW", 0, 1);
    set_par(l+"A", 0, 1);
  }
}


%%%%%%%%%%%%%%%%%%%
define compare_pars(a, b)
%%%%%%%%%%%%%%%%%%%
{ a = get_par(a);
  b = get_par(b);
  if(a<=b) { return -1; } else { if(a==b) { return +1; } else { return +1; } }
}


%%%%%%%%%%%%%%%%%%%
define get_line_ids()
%%%%%%%%%%%%%%%%%%%
{
  variable line;
  switch(_NARGS)
  { case 1: line = (); }
  { help(_function_name()); return; }

  switch(line)
  { case "O8a": return [99080821]; }  %  (O VIII alpha)
  { case "O8b": return [99080822]; }  %  (O VIII beta)
  { case "O8g": return [99080823]; }  %  (O VIII gamma)
  { case "O8d": return [99080824]; }  %  (O VIII delta)
  { case "O7f": return [99080719]; }  %  (O VII f)
  { case "O7i": return [99080720]; }  %  (O VII i)
  { case "O7a": return [99080721]; }  %  (O VII alpha)
  { case "O7b": return [99080722]; }  %  (O VII beta)
  { case "O7g": return [99080723]; }  %  (O VII gamma)
  { case "O7d": return [99080724]; }  %  (O VII delta)
  { case "Ne10a": return [99101021]; }  %  (Ne X alpha)
  { case "Ne10b": return [99101022]; }  %  (Ne X beta)
  { case "Ne10g": return [99101023]; }  %  (Ne X gamma)
  { case "Ne10d": return [99101024]; }  %  (Ne X delta)
  { case "Ne10e": return [99101025]; }  %  (Ne X epsilon)
  { case "Ne10z": return [99101026]; }  %  (Ne X zeta)
  { case "Ne9f": return [99100919]; }  %  (Ne IX f)
  { case "Ne9i": return [99100920]; }  %  (Ne IX i)
  { case "Ne9a": return [99100921]; }  %  (Ne IX alpha)
  { case "Ne9b": return [99100922]; }  %  (Ne IX beta)
  { case "Ne9g": return [99100923]; }  %  (Ne IX gamma)
  { case "Ne9d": return [99100924]; }  %  (Ne IX delta)
  { case "Ne9e": return [99100925]; }  %  (Ne IX epsilon)
  { case "Ne9z": return [99100926]; }  %  (Ne IX zeta)
  { case "Na11a": return [99111121]; }  %  (Na XI alpha)
  { case "Na11b": return [99111122]; }  %  (Na XI beta)
  { case "Na11g": return [99111123]; }  %  (Na XI gamma)
  { case "Na11d": return [99111124]; }  %  (Na XI delta)
  { case "Na10f": return [99111019]; }  %  (Na X f)
  { case "Na10i": return [99111020]; }  %  (Na X i)
  { case "Na10a": return [99111021]; }  %  (Na X alpha)
  { case "Na10b": return [99111022]; }  %  (Na X beta)
  { case "Na10g": return [99111023]; }  %  (Na X gamma)
  { case "Na10d": return [99111024]; }  %  (Na X delta)
  { case "Mg12a": return [99121221]; }  %  (Mg XII alpha)
  { case "Mg12b": return [99121222]; }  %  (Mg XII beta)
  { case "Mg12g": return [99121223]; }  %  (Mg XII gamma)
  { case "Mg12d": return [99121224]; }  %  (Mg XII delta)
  { case "Mg11f": return [99121119]; }  %  (Mg XI f)
  { case "Mg11i": return [99121120]; }  %  (Mg XI i)
  { case "Mg11a": return [99121121]; }  %  (Mg XI alpha)
  { case "Mg11b": return [99121122]; }  %  (Mg XI beta)
  { case "Mg11g": return [99121123]; }  %  (Mg XI gamma)
  { case "Mg11d": return [99121124]; }  %  (Mg XI delta)
  { case "Al13a": return [99131321]; }  %  (Al XIII alpha)
  { case "Al13b": return [99131322]; }  %  (Al XIII beta)
  { case "Al13g": return [99131323]; }  %  (Al XIII gamma)
  { case "Al13d": return [99131324]; }  %  (Al XIII delta)
  { case "Al12f": return [99131219]; }  %  (Al XII f)
  { case "Al12i": return [99131220]; }  %  (Al XII i)
  { case "Al12a": return [99131221]; }  %  (Al XII alpha)
  { case "Al12b": return [99131222]; }  %  (Al XII beta)
  { case "Al12g": return [99131223]; }  %  (Al XII gamma)
  { case "Al12d": return [99131224]; }  %  (Al XII delta)
  { case "Si14a": return [99141421]; }  %  (Si XIV alpha)
  { case "Si14b": return [99141422]; }  %  (Si XIV beta)
  { case "Si14g": return [99141423]; }  %  (Si XIV gamma)
  { case "Si14d": return [99141424]; }  %  (Si XIV delta)
  { case "Si13f": return [99141319]; }  %  (Si XIII f)
  { case "Si13i": return [99141320]; }  %  (Si XIII i)
  { case "Si13a": return [99141321]; }  %  (Si XIII alpha)
  { case "Si13b": return [99141322]; }  %  (Si XIII beta)
  { case "Si13g": return [99141323]; }  %  (Si XIII gamma)
  { case "Si13d": return [99141324]; }  %  (Si XIII delta)
  { case "S16a": return [99161621]; }  %  (S XVI alpha)
  { case "S16b": return [99161622]; }  %  (S XVI beta)
  { case "S16g": return [99161623]; }  %  (S XVI gamma)
  { case "S16d": return [99161624]; }  %  (S XVI delta)
  { case "S15f": return [99161519]; }  %  (S XV f)
  { case "S15i": return [99161520]; }  %  (S XV i)
  { case "S15a": return [99161521]; }  %  (S XV alpha)
  { case "S15b": return [99161522]; }  %  (S XV beta)
  { case "S15g": return [99161523]; }  %  (S XV gamma)
  { case "S15d": return [99161524]; }  %  (S XV delta)
  { case "Ar18a": return [99181821]; }  %  (Ar XVIII alpha)
  { case "Ar18b": return [99181822]; }  %  (Ar XVIII beta)
  { case "Ar18g": return [99181823]; }  %  (Ar XVIII gamma)
  { case "Ar18d": return [99181824]; }  %  (Ar XVIII delta)
  { case "Ar17f": return [99181719]; }  %  (Ar XVII f)
  { case "Ar17i": return [99181720]; }  %  (Ar XVII i)
  { case "Ar17a": return [99181721]; }  %  (Ar XVII alpha)
  { case "Ar17b": return [99181722]; }  %  (Ar XVII beta)
  { case "Ar17g": return [99181723]; }  %  (Ar XVII gamma)
  { case "Ar17d": return [99181724]; }  %  (Ar XVII delta)
  { case "Ca20a": return [99202021]; }  %  (Ca XX alpha)
  { case "Ca20b": return [99202022]; }  %  (Ca XX beta)
  { case "Ca20g": return [99202023]; }  %  (Ca XX gamma)
  { case "Ca20d": return [99202024]; }  %  (Ca XX delta)
  { case "Ca19f": return [99201919]; }  %  (Ca XIX f)
  { case "Ca19i": return [99201920]; }  %  (Ca XIX i)
  { case "Ca19a": return [99201921]; }  %  (Ca XIX alpha)
  { case "Ca19b": return [99201922]; }  %  (Ca XIX beta)
  { case "Ca19g": return [99201923]; }  %  (Ca XIX gamma)
  { case "Ca19d": return [99201924]; }  %  (Ca XIX delta)
  { case "Fe26a": return [99262621]; }  %  (Fe XXVI alpha)
  { case "Fe26b": return [99262622]; }  %  (Fe XXVI beta)
  { case "Fe26g": return [99262623]; }  %  (Fe XXVI gamma)
  { case "Fe26d": return [99262624]; }  %  (Fe XXVI delta)
  { case "Fe25f": return [99262519]; }  %  (Fe XXV f)
  { case "Fe25i": return [99262520]; }  %  (Fe XXV i)
  { case "Fe25a": return [99262521]; }  %  (Fe XXV alpha)
  { case "Fe25b": return [99262522]; }  %  (Fe XXV beta)
  { case "Fe25g": return [99262523]; }  %  (Fe XXV gamma)
  { case "Fe25d": return [99262524]; }  %  (Fe XXV delta)
  { case "Fe1Ka": return [99260101]; }  %  (Fe I Kalpha)
  { case "Fe24_1062A": return [161758]; }  %  (161758)
  { case "Fe24_679A": return [161756]; }  %  (161756)
  { case "bl_1066A": return [161753, 18204]; }  %  (161753, 18204) = (Fe XXIV, Fe XVII)
  { case "Fe24_799A": return [161759, 161754]; }  %  (161759, 161754)
  { case "bl_1102A": return [149890, 18163]; }  %  (149890, 18163) = (Fe XXIII, Fe XVII)
  { case "bl_1099A": return [149893, 131886]; }  %  (149893, 131886) = (Fe XXIII, Fe XXII)
  { case "Fe23_830A": return [149914]; }  %  (149914)
  { case "Fe22_1225A": return [131880]; }  %  (131880)
  { case "Fe22_1143A": return [132636]; }  %  (132636)
  { case "Fe22_897A": return [132642]; }  %  (132642)
  { case "Fe22_1193A": return [132890]; }  %  (132890)
  { case "bl_1177A": return [132626, 75499]; }  %  (132626, 75499) = (Fe XXII, Fe XX)
  { case "Fe22_1149A": return [131888, 132634]; }  %  (131888, 132634)
  { case "Fe22_873A": return [131902, 132644]; }  %  (131902, 132644)
  { case "Fe22_786A": return [131918, 132676]; }  %  (131918, 132676)
  { case "Fe21_1228A": return [128657]; }  %  (128657)
  { case "Fe21_1198A": return [128681]; }  %  (128681)
  { case "Fe21_1304A": return [128653]; }  %  (128653)
  { case "bl_920A": return [128775, 75070, 74587]; }  %  (128775, 75070, 74587) = (Fe XXI, Fe XX, Fe XX)
  { case "Fe21_857A": return [128847, 131702, 129682]; }  %  (128847, 131702, 129682)
  { case "Fe21_1233A": return [131540]; }  %  (131540)
  { case "Fe20_1292A": return [75469, 74908]; }  %  (75469, 74908)
  { case "Fe20_1286A": return [74900, 75472]; }  %  (74900, 75472)
  { case "Fe20_1283A": return [74354, 74360]; }  %  (74354, 74360)
  { case "Fe20_1258A": return [74924, 75496]; }  %  (74924, 75496)
  { case "Fe20_1000A": return [74457, 75036, 74463, 75579]; }  %  (74457, 75036, 74463, 75579)
  { case "Fe20_1297A": return [75461, 74351]; }  %  (75461, 74351)
  { case "bl_1012A": return [75587, 39003, 18189]; }  %  (75587, 39003, 18189) = (Fe XX, Fe XIX, Fe XVII)
  { case "bl_1301A": return [74897, 39144]; }  %  (74897, 39144) = (Fe XX, Fe XIX)
  { case "Fe19_1466A": return [39118]; }  %  (39118)
  { case "Fe19_1380A": return [39132]; }  %  (39132)
  { case "Fe19_1364A": return [39124]; }  %  (39124)
  { case "Fe19_1350A": return [38915]; }  %  (38915)
  { case "Fe19_1346A": return [38603]; }  %  (38603)
  { case "Fe19_1342A": return [39134]; }  %  (39134)
  { case "Fe19_1294A": return [38634]; }  %  (38634)
  { case "Fe19_1082A": return [39172]; }  %  (39172)
  { case "Fe19_1013A": return [38692]; }  %  (38692)
  { case "Fe19_986A": return [39223]; }  %  (39223)
  { case "Fe19_1352A": return [39128, 38611]; }  %  (39128, 38611)
  { case "Fe19_1293A": return [38941, 39146]; }  %  (38941, 39146)
  { case "Fe18_1453A": return [38000]; }  %  (38000)
  { case "Fe18_1437A": return [37997]; }  %  (37997)
  { case "Fe18_1457A": return [37942]; }  %  (37942)
  { case "Fe18_1562A": return [37995]; }  %  (37995)
  { case "Fe18_1332A": return [37835]; }  %  (37835)
  { case "Fe18_1426A": return [37830, 38002]; }  %  (37830, 38002)
  { case "Fe18_1421A": return [37944, 37998, 38112]; }  %  (37944, 37998, 38112)
  { case "Fe18_1153A": return [37961, 38014]; }  %  (37961, 38014)
  { case "Fe18_1133A": return [37845, 37963, 38012]; }  %  (37845, 37963, 38012)
  { case "Fe17_1678A": return [20125]; }  %  (20125)
  { case "Fe17_1526A": return [20128]; }  %  (20128)
  { case "Fe17_1501A": return [20127]; }  %  (20127)
  { case "Fe17_1227A": return [18155]; }  %  (18155)
  { case "Fe17_1212A": return [18151]; }  %  (18151)
  { case "Fe17_1536A": return [25066]; }  %  (25066)
  { case "Fe17_1382A": return [20130]; }  %  (20130)
  { case "bl_1384A": return [38918, 74885]; }  %  (38918, 74885) = (Fe XIX, Fe XX)
  { case "Al11Ka": return [99131101]; }  %  (Al XI Kalpha)
  { case "Al10Ka": return [99131001]; }  %  (Al X Kalpha)
  { case "Al9Ka": return [99130901]; }  %  (Al IX Kalpha)
  { case "Al8Ka": return [99130801]; }  %  (Al VIII Kalpha)
  { case "Al7Ka": return [99130701]; }  %  (Al VII Kalpha)
  { case "Al6Ka": return [99130601]; }  %  (Al VI Kalpha)
  { case "Al5Ka": return [99130501]; }  %  (Al V Kalpha)
  { case "Al4Ka": return [99130401]; }  %  (Al IV Kalpha)
  { case "Al3Ka": return [99130301]; }  %  (Al III Kalpha)
  { case "Al2Ka": return [99130201]; }  %  (Al II Kalpha)
  { case "Si12Ka": return [99141201]; }  %  (Si XII Kalpha)
  { case "Si11Ka": return [99141101]; }  %  (Si XI Kalpha)
  { case "Si10Ka": return [99141001]; }  %  (Si X Kalpha)
  { case "Si9Ka": return [99140901]; }  %  (Si IX Kalpha)
  { case "Si8Ka": return [99140801]; }  %  (Si VIII Kalpha)
  { case "Si7Ka": return [99140701]; }  %  (Si VII Kalpha)
  { case "Si6Ka": return [99140601]; }  %  (Si VI Kalpha)
  { case "Si5Ka": return [99140501]; }  %  (Si V Kalpha)
  { case "Si4Ka": return [99140401]; }  %  (Si IV Kalpha)
  { case "Si3Ka": return [99140301]; }  %  (Si III Kalpha)
  { case "Si2Ka": return [99140201]; }  %  (Si II Kalpha)
  { case "Ar16Ka": return [99181601]; }  %  (Ar XVI Kalpha)
  { case "Ar15Ka": return [99181501]; }  %  (Ar XV Kalpha)
  { case "Ar14Ka": return [99181401]; }  %  (Ar XIV Kalpha)
  { case "Ar13Ka": return [99181301]; }  %  (Ar XIII Kalpha)
  { case "Ar12Ka": return [99181201]; }  %  (Ar XII Kalpha)
  { case "Ar11Ka": return [99181101]; }  %  (Ar XI Kalpha)
  { case "Ar10Ka": return [99181001]; }  %  (Ar X Kalpha)
  { case "Ar9Ka": return [99180901]; }  %  (Ar IX Kalpha)
  { case "Ar8Ka": return [99180801]; }  %  (Ar VIII Kalpha)
  { case "Ar7Ka": return [99180701]; }  %  (Ar VII Kalpha)
  { case "Ar6Ka": return [99180601]; }  %  (Ar VI Kalpha)
  { case "Ar5Ka": return [99180501]; }  %  (Ar V Kalpha)
  { case "Ar4Ka": return [99180401]; }  %  (Ar IV Kalpha)
  { case "Ar3Ka": return [99180301]; }  %  (Ar III Kalpha)
  { case "Ar2Ka": return [99180201]; }  %  (Ar II Kalpha)
  { vmessage("error (%s): line %s is unknown.", _function_name(), line); return; }
}


%%%%%%%%%%%%%%%%%%%%%%%
define get_line_lambdas()
%%%%%%%%%%%%%%%%%%%%%%%
{
  variable line;
  switch(_NARGS)
  { case 1: line = (); }
  { help(_function_name()); return; }

  switch(line)
  { case "O8a": return [18.968912]; }  %  (O VIII alpha)
  { case "O8b": return [16.005899]; }  %  (O VIII beta)
  { case "O8g": return [15.176164]; }  %  (O VIII gamma)
  { case "O8d": return [14.820574]; }  %  (O VIII delta)
  { case "O7f": return [22.097725]; }  %  (O VII f)
  { case "O7i": return [21.803638]; }  %  (O VII i)
  { case "O7a": return [21.601503]; }  %  (O VII alpha)
  { case "O7b": return [18.627001]; }  %  (O VII beta)
  { case "O7g": return [17.768000]; }  %  (O VII gamma)
  { case "O7d": return [17.396000]; }  %  (O VII delta)
  { case "Ne10a": return [12.133888]; }  %  (Ne X alpha)
  { case "Ne10b": return [10.238855]; }  %  (Ne X beta)
  { case "Ne10g": return [9.708176]; }  %  (Ne X gamma)
  { case "Ne10d": return [9.480745]; }  %  (Ne X delta)
  { case "Ne10e": return [9.361633]; }  %  (Ne X epsilon)
  { case "Ne10z": return [9.291233]; }  %  (Ne X zeta)
  { case "Ne9f": return [13.698976]; }  %  (Ne IX f)
  { case "Ne9i": return [13.553110]; }  %  (Ne IX i)
  { case "Ne9a": return [13.447307]; }  %  (Ne IX alpha)
  { case "Ne9b": return [11.544000]; }  %  (Ne IX beta)
  { case "Ne9g": return [11.001000]; }  %  (Ne IX gamma)
  { case "Ne9d": return [10.765000]; }  %  (Ne IX delta)
  { case "Ne9e": return [10.642600]; }  %  (Ne IX epsilon)
  { case "Ne9z": return [10.565000]; }  %  (Ne IX zeta)
  { case "Na11a": return [10.025000]; }  %  (Na XI alpha)
  { case "Na11b": return [8.459500]; }  %  (Na XI beta)
  { case "Na11g": return [8.021067]; }  %  (Na XI gamma)
  { case "Na11d": return [7.833167]; }  %  (Na XI delta)
  { case "Na10f": return [11.190000]; }  %  (Na X f)
  { case "Na10i": return [11.080000]; }  %  (Na X i)
  { case "Na10a": return [11.002700]; }  %  (Na X alpha)
  { case "Na10b": return [9.433000]; }  %  (Na X beta)
  { case "Na10g": return [8.982800]; }  %  (Na X gamma)
  { case "Na10d": return [8.788400]; }  %  (Na X delta)
  { case "Mg12a": return [8.421013]; }  %  (Mg XII alpha)
  { case "Mg12b": return [7.106155]; }  %  (Mg XII beta)
  { case "Mg12g": return [6.737902]; }  %  (Mg XII gamma)
  { case "Mg12d": return [6.580088]; }  %  (Mg XII delta)
  { case "Mg11f": return [9.314339]; }  %  (Mg XI f)
  { case "Mg11i": return [9.231208]; }  %  (Mg XI i)
  { case "Mg11a": return [9.168750]; }  %  (Mg XI alpha)
  { case "Mg11b": return [7.850300]; }  %  (Mg XI beta)
  { case "Mg11g": return [7.473000]; }  %  (Mg XI gamma)
  { case "Mg11d": return [7.310100]; }  %  (Mg XI delta)
  { case "Al13a": return [7.172800]; }  %  (Al XIII alpha)
  { case "Al13b": return [6.052967]; }  %  (Al XIII beta)
  { case "Al13g": return [5.739333]; }  %  (Al XIII gamma)
  { case "Al13d": return [5.604867]; }  %  (Al XIII delta)
  { case "Al12f": return [7.872118]; }  %  (Al XII f)
  { case "Al12i": return [7.806957]; }  %  (Al XII i)
  { case "Al12a": return [7.757301]; }  %  (Al XII alpha)
  { case "Al12b": return [6.635000]; }  %  (Al XII beta)
  { case "Al12g": return [6.314000]; }  %  (Al XII gamma)
  { case "Al12d": return [6.175000]; }  %  (Al XII delta)
  { case "Si14a": return [6.182241]; }  %  (Si XIV alpha)
  { case "Si14b": return [5.217208]; }  %  (Si XIV beta)
  { case "Si14g": return [4.946905]; }  %  (Si XIV gamma)
  { case "Si14d": return [4.831070]; }  %  (Si XIV delta)
  { case "Si13f": return [6.740294]; }  %  (Si XIII f)
  { case "Si13i": return [6.688187]; }  %  (Si XIII i)
  { case "Si13a": return [6.647947]; }  %  (Si XIII alpha)
  { case "Si13b": return [5.680500]; }  %  (Si XIII beta)
  { case "Si13g": return [5.404500]; }  %  (Si XIII gamma)
  { case "Si13d": return [5.285000]; }  %  (Si XIII delta)
  { case "S16a": return [4.729170]; }  %  (S XVI alpha)
  { case "S16b": return [3.991193]; }  %  (S XVI beta)
  { case "S16g": return [3.784465]; }  %  (S XVI gamma)
  { case "S16d": return [3.695877]; }  %  (S XVI delta)
  { case "S15f": return [5.101501]; }  %  (S XV f)
  { case "S15i": return [5.066492]; }  %  (S XV i)
  { case "S15a": return [5.038726]; }  %  (S XV alpha)
  { case "S15b": return [4.299000]; }  %  (S XV beta)
  { case "S15g": return [4.088300]; }  %  (S XV gamma)
  { case "S15d": return [3.998000]; }  %  (S XV delta)
  { case "Ar18a": return [3.732922]; }  %  (Ar XVIII alpha)
  { case "Ar18b": return [3.150621]; }  %  (Ar XVIII beta)
  { case "Ar18g": return [2.987481]; }  %  (Ar XVIII gamma)
  { case "Ar18d": return [2.917574]; }  %  (Ar XVIII delta)
  { case "Ar17f": return [3.994153]; }  %  (Ar XVII f)
  { case "Ar17i": return [3.969363]; }  %  (Ar XVII i)
  { case "Ar17a": return [3.949075]; }  %  (Ar XVII alpha)
  { case "Ar17b": return [3.365000]; }  %  (Ar XVII beta)
  { case "Ar17g": return [3.200000]; }  %  (Ar XVII gamma)
  { case "Ar17d": return [3.128000]; }  %  (Ar XVII delta)
  { case "Ca20a": return [3.020304]; }  %  (Ca XX alpha)
  { case "Ca20b": return [2.549359]; }  %  (Ca XX beta)
  { case "Ca20g": return [2.417399]; }  %  (Ca XX gamma)
  { case "Ca20d": return [2.360854]; }  %  (Ca XX delta)
  { case "Ca19f": return [3.211031]; }  %  (Ca XIX f)
  { case "Ca19i": return [3.192747]; }  %  (Ca XIX i)
  { case "Ca19a": return [3.177153]; }  %  (Ca XIX alpha)
  { case "Ca19b": return [2.705000]; }  %  (Ca XIX beta)
  { case "Ca19g": return [2.571000]; }  %  (Ca XIX gamma)
  { case "Ca19d": return [2.514000]; }  %  (Ca XIX delta)
  { case "Fe26a": return [1.779852]; }  %  (Fe XXVI alpha)
  { case "Fe26b": return [1.502752]; }  %  (Fe XXVI beta)
  { case "Fe26g": return [1.425067]; }  %  (Fe XXVI gamma)
  { case "Fe26d": return [1.391783]; }  %  (Fe XXVI delta)
  { case "Fe25f": return [1.868194]; }  %  (Fe XXV f)
  { case "Fe25i": return [1.859517]; }  %  (Fe XXV i)
  { case "Fe25a": return [1.850399]; }  %  (Fe XXV alpha)
  { case "Fe25b": return [1.573100]; }  %  (Fe XXV beta)
  { case "Fe25g": return [1.495000]; }  %  (Fe XXV gamma)
  { case "Fe25d": return [1.461000]; }  %  (Fe XXV delta)
  { case "Fe1Ka": return [1.937000]; }  %  (Fe I Kalpha)
  { case "Fe24_1062A": return [10.619000]; }  %  (161758)
  { case "Fe24_679A": return [6.788690]; }  %  (161756)
  { case "bl_1066A": return [10.663000, 10.657000]; }  %  (161753, 18204) = (Fe XXIV, Fe XVII)
  { case "Fe24_799A": return [7.985700, 7.996000]; }  %  (161759, 161754)
  { case "bl_1102A": return [11.019000, 11.026000]; }  %  (149890, 18163) = (Fe XXIII, Fe XVII)
  { case "bl_1099A": return [10.981000, 10.993500]; }  %  (149893, 131886) = (Fe XXIII, Fe XXII)
  { case "Fe23_830A": return [8.303800]; }  %  (149914)
  { case "Fe22_1225A": return [12.251900]; }  %  (131880)
  { case "Fe22_1143A": return [11.427000]; }  %  (132636)
  { case "Fe22_897A": return [8.974800]; }  %  (132642)
  { case "Fe22_1193A": return [11.932000]; }  %  (132890)
  { case "bl_1177A": return [11.770000, 11.762000]; }  %  (132626, 75499) = (Fe XXII, Fe XX)
  { case "Fe22_1149A": return [11.490000, 11.490000]; }  %  (131888, 132634)
  { case "Fe22_873A": return [8.725410, 8.736000]; }  %  (131902, 132644)
  { case "Fe22_786A": return [7.865000, 7.865000]; }  %  (131918, 132676)
  { case "Fe21_1228A": return [12.284000]; }  %  (128657)
  { case "Fe21_1198A": return [11.975000]; }  %  (128681)
  { case "Fe21_1304A": return [13.044400]; }  %  (128653)
  { case "bl_920A": return [9.194400, 9.197920, 9.197850]; }  %  (128775, 75070, 74587) = (Fe XXI, Fe XX, Fe XX)
  { case "Fe21_857A": return [8.574000, 8.574000, 8.574000]; }  %  (128847, 131702, 129682)
  { case "Fe21_1233A": return [12.327000]; }  %  (131540)
  { case "Fe20_1292A": return [12.912000, 12.921100]; }  %  (75469, 74908)
  { case "Fe20_1286A": return [12.846000, 12.864000]; }  %  (74900, 75472)
  { case "Fe20_1283A": return [12.824000, 12.827000]; }  %  (74354, 74360)
  { case "Fe20_1258A": return [12.576000, 12.576000]; }  %  (74924, 75496)
  { case "Fe20_1000A": return [9.997740, 10.000400, 9.993450, 10.005400]; }  %  (74457, 75036, 74463, 75579)
  { case "Fe20_1297A": return [12.965000, 12.965400]; }  %  (75461, 74351)
  { case "bl_1012A": return [10.120300, 10.119500, 10.121000]; }  %  (75587, 39003, 18189) = (Fe XX, Fe XIX, Fe XVII)
  { case "bl_1301A": return [12.992000, 13.022000]; }  %  (74897, 39144) = (Fe XX, Fe XIX)
  { case "Fe19_1466A": return [14.664000]; }  %  (39118)
  { case "Fe19_1380A": return [13.795000]; }  %  (39132)
  { case "Fe19_1364A": return [13.645000]; }  %  (39124)
  { case "Fe19_1350A": return [13.497000]; }  %  (38915)
  { case "Fe19_1346A": return [13.462000]; }  %  (38603)
  { case "Fe19_1342A": return [13.423000]; }  %  (39134)
  { case "Fe19_1294A": return [12.945000]; }  %  (38634)
  { case "Fe19_1082A": return [10.816000]; }  %  (39172)
  { case "Fe19_1013A": return [10.130900]; }  %  (38692)
  { case "Fe19_986A": return [9.855220]; }  %  (39223)
  { case "Fe19_1352A": return [13.518000, 13.514600]; }  %  (39128, 38611)
  { case "Fe19_1293A": return [12.931100, 12.933000]; }  %  (38941, 39146)
  { case "Fe18_1453A": return [14.534000]; }  %  (38000)
  { case "Fe18_1437A": return [14.373000]; }  %  (37997)
  { case "Fe18_1457A": return [14.571000]; }  %  (37942)
  { case "Fe18_1562A": return [15.625000]; }  %  (37995)
  { case "Fe18_1332A": return [13.323000]; }  %  (37835)
  { case "Fe18_1426A": return [14.256000, 14.256000]; }  %  (37830, 38002)
  { case "Fe18_1421A": return [14.208000, 14.208000, 14.200700]; }  %  (37944, 37998, 38112)
  { case "Fe18_1153A": return [11.527000, 11.527000]; }  %  (37961, 38014)
  { case "Fe18_1133A": return [11.326000, 11.326000, 11.326000]; }  %  (37845, 37963, 38012)
  { case "Fe17_1678A": return [16.780001]; }  %  (20125)
  { case "Fe17_1526A": return [15.261000]; }  %  (20128)
  { case "Fe17_1501A": return [15.014000]; }  %  (20127)
  { case "Fe17_1227A": return [12.266000]; }  %  (18155)
  { case "Fe17_1212A": return [12.124000]; }  %  (18151)
  { case "Fe17_1536A": return [15.359700]; }  %  (25066)
  { case "Fe17_1382A": return [13.825000]; }  %  (20130)
  { case "bl_1384A": return [13.839000, 13.843000]; }  %  (38918, 74885) = (Fe XIX, Fe XX)
  { case "Al11Ka": return [7.885000]; }  %  (Al XI Kalpha)
  { case "Al10Ka": return [7.964000]; }  %  (Al X Kalpha)
  { case "Al9Ka": return [8.050000]; }  %  (Al IX Kalpha)
  { case "Al8Ka": return [8.129000]; }  %  (Al VIII Kalpha)
  { case "Al7Ka": return [8.203000]; }  %  (Al VII Kalpha)
  { case "Al6Ka": return [8.269000]; }  %  (Al VI Kalpha)
  { case "Al5Ka": return [8.328000]; }  %  (Al V Kalpha)
  { case "Al4Ka": return [8.332000]; }  %  (Al IV Kalpha)
  { case "Al3Ka": return [8.336000]; }  %  (Al III Kalpha)
  { case "Al2Ka": return [8.339000]; }  %  (Al II Kalpha)
  { case "Si12Ka": return [6.750000]; }  %  (Si XII Kalpha)
  { case "Si11Ka": return [6.813000]; }  %  (Si XI Kalpha)
  { case "Si10Ka": return [6.882000]; }  %  (Si X Kalpha)
  { case "Si9Ka": return [6.947000]; }  %  (Si IX Kalpha)
  { case "Si8Ka": return [7.007000]; }  %  (Si VIII Kalpha)
  { case "Si7Ka": return [7.063000]; }  %  (Si VII Kalpha)
  { case "Si6Ka": return [7.112000]; }  %  (Si VI Kalpha)
  { case "Si5Ka": return [7.117000]; }  %  (Si V Kalpha)
  { case "Si4Ka": return [7.121000]; }  %  (Si IV Kalpha)
  { case "Si3Ka": return [7.124000]; }  %  (Si III Kalpha)
  { case "Si2Ka": return [7.126000]; }  %  (Si II Kalpha)
  { case "Ar16Ka": return [3.995000]; }  %  (Ar XVI Kalpha)
  { case "Ar15Ka": return [4.025000]; }  %  (Ar XV Kalpha)
  { case "Ar14Ka": return [4.057000]; }  %  (Ar XIV Kalpha)
  { case "Ar13Ka": return [4.089000]; }  %  (Ar XIII Kalpha)
  { case "Ar12Ka": return [4.119000]; }  %  (Ar XII Kalpha)
  { case "Ar11Ka": return [4.147000]; }  %  (Ar XI Kalpha)
  { case "Ar10Ka": return [4.174000]; }  %  (Ar X Kalpha)
  { case "Ar9Ka": return [4.178000]; }  %  (Ar IX Kalpha)
  { case "Ar8Ka": return [4.180000]; }  %  (Ar VIII Kalpha)
  { case "Ar7Ka": return [4.184000]; }  %  (Ar VII Kalpha)
  { case "Ar6Ka": return [4.186000]; }  %  (Ar VI Kalpha)
  { case "Ar5Ka": return [4.189000]; }  %  (Ar V Kalpha)
  { case "Ar4Ka": return [4.190000]; }  %  (Ar IV Kalpha)
  { case "Ar3Ka": return [4.192000]; }  %  (Ar III Kalpha)
  { case "Ar2Ka": return [4.193000]; }  %  (Ar II Kalpha)
  { message("error ("+_function_name()+"): line "+line+" is unknown."); return; }
}


%%%%%%%%%%%%%%%%%%%%%%%%%%
define get_line_transition()
%%%%%%%%%%%%%%%%%%%%%%%%%%
{
  variable line;
  switch(_NARGS)
  { case 1: line = (); }
  { help(_function_name()); return; }

  switch(line)
  { case "O8a": return [8, 8, 21]; }  %  (O VIII alpha)
  { case "O8b": return [8, 8, 22]; }  %  (O VIII beta)
  { case "O8g": return [8, 8, 23]; }  %  (O VIII gamma)
  { case "O8d": return [8, 8, 24]; }  %  (O VIII delta)
  { case "O7f": return [8, 7, 19]; }  %  (O VII f)
  { case "O7i": return [8, 7, 20]; }  %  (O VII i)
  { case "O7a": return [8, 7, 21]; }  %  (O VII alpha)
  { case "O7b": return [8, 7, 22]; }  %  (O VII beta)
  { case "O7g": return [8, 7, 23]; }  %  (O VII gamma)
  { case "O7d": return [8, 7, 24]; }  %  (O VII delta)
  { case "Ne10a": return [10, 10, 21]; }  %  (Ne X alpha)
  { case "Ne10b": return [10, 10, 22]; }  %  (Ne X beta)
  { case "Ne10g": return [10, 10, 23]; }  %  (Ne X gamma)
  { case "Ne10d": return [10, 10, 24]; }  %  (Ne X delta)
  { case "Ne10e": return [10, 10, 25]; }  %  (Ne X epsilon)
  { case "Ne10z": return [10, 10, 26]; }  %  (Ne X zeta)
  { case "Ne9f": return [10, 9, 19]; }  %  (Ne IX f)
  { case "Ne9i": return [10, 9, 20]; }  %  (Ne IX i)
  { case "Ne9a": return [10, 9, 21]; }  %  (Ne IX alpha)
  { case "Ne9b": return [10, 9, 22]; }  %  (Ne IX beta)
  { case "Ne9g": return [10, 9, 23]; }  %  (Ne IX gamma)
  { case "Ne9d": return [10, 9, 24]; }  %  (Ne IX delta)
  { case "Ne9e": return [10, 9, 25]; }  %  (Ne IX epsilon)
  { case "Ne9z": return [10, 9, 26]; }  %  (Ne IX zeta)
  { case "Na11a": return [11, 11, 21]; }  %  (Na XI alpha)
  { case "Na11b": return [11, 11, 22]; }  %  (Na XI beta)
  { case "Na11g": return [11, 11, 23]; }  %  (Na XI gamma)
  { case "Na11d": return [11, 11, 24]; }  %  (Na XI delta)
  { case "Na10f": return [11, 10, 19]; }  %  (Na X f)
  { case "Na10i": return [11, 10, 20]; }  %  (Na X i)
  { case "Na10a": return [11, 10, 21]; }  %  (Na X alpha)
  { case "Na10b": return [11, 10, 22]; }  %  (Na X beta)
  { case "Na10g": return [11, 10, 23]; }  %  (Na X gamma)
  { case "Na10d": return [11, 10, 24]; }  %  (Na X delta)
  { case "Mg12a": return [12, 12, 21]; }  %  (Mg XII alpha)
  { case "Mg12b": return [12, 12, 22]; }  %  (Mg XII beta)
  { case "Mg12g": return [12, 12, 23]; }  %  (Mg XII gamma)
  { case "Mg12d": return [12, 12, 24]; }  %  (Mg XII delta)
  { case "Mg11f": return [12, 11, 19]; }  %  (Mg XI f)
  { case "Mg11i": return [12, 11, 20]; }  %  (Mg XI i)
  { case "Mg11a": return [12, 11, 21]; }  %  (Mg XI alpha)
  { case "Mg11b": return [12, 11, 22]; }  %  (Mg XI beta)
  { case "Mg11g": return [12, 11, 23]; }  %  (Mg XI gamma)
  { case "Mg11d": return [12, 11, 24]; }  %  (Mg XI delta)
  { case "Al13a": return [13, 13, 21]; }  %  (Al XIII alpha)
  { case "Al13b": return [13, 13, 22]; }  %  (Al XIII beta)
  { case "Al13g": return [13, 13, 23]; }  %  (Al XIII gamma)
  { case "Al13d": return [13, 13, 24]; }  %  (Al XIII delta)
  { case "Al12f": return [13, 12, 19]; }  %  (Al XII f)
  { case "Al12i": return [13, 12, 20]; }  %  (Al XII i)
  { case "Al12a": return [13, 12, 21]; }  %  (Al XII alpha)
  { case "Al12b": return [13, 12, 22]; }  %  (Al XII beta)
  { case "Al12g": return [13, 12, 23]; }  %  (Al XII gamma)
  { case "Al12d": return [13, 12, 24]; }  %  (Al XII delta)
  { case "Si14a": return [14, 14, 21]; }  %  (Si XIV alpha)
  { case "Si14b": return [14, 14, 22]; }  %  (Si XIV beta)
  { case "Si14g": return [14, 14, 23]; }  %  (Si XIV gamma)
  { case "Si14d": return [14, 14, 24]; }  %  (Si XIV delta)
  { case "Si13f": return [14, 13, 19]; }  %  (Si XIII f)
  { case "Si13i": return [14, 13, 20]; }  %  (Si XIII i)
  { case "Si13a": return [14, 13, 21]; }  %  (Si XIII alpha)
  { case "Si13b": return [14, 13, 22]; }  %  (Si XIII beta)
  { case "Si13g": return [14, 13, 23]; }  %  (Si XIII gamma)
  { case "Si13d": return [14, 13, 24]; }  %  (Si XIII delta)
  { case "S16a": return [16, 16, 21]; }  %  (S XVI alpha)
  { case "S16b": return [16, 16, 22]; }  %  (S XVI beta)
  { case "S16g": return [16, 16, 23]; }  %  (S XVI gamma)
  { case "S16d": return [16, 16, 24]; }  %  (S XVI delta)
  { case "S15f": return [16, 15, 19]; }  %  (S XV f)
  { case "S15i": return [16, 15, 20]; }  %  (S XV i)
  { case "S15a": return [16, 15, 21]; }  %  (S XV alpha)
  { case "S15b": return [16, 15, 22]; }  %  (S XV beta)
  { case "S15g": return [16, 15, 23]; }  %  (S XV gamma)
  { case "S15d": return [16, 15, 24]; }  %  (S XV delta)
  { case "Ar18a": return [18, 18, 21]; }  %  (Ar XVIII alpha)
  { case "Ar18b": return [18, 18, 22]; }  %  (Ar XVIII beta)
  { case "Ar18g": return [18, 18, 23]; }  %  (Ar XVIII gamma)
  { case "Ar18d": return [18, 18, 24]; }  %  (Ar XVIII delta)
  { case "Ar17f": return [18, 17, 19]; }  %  (Ar XVII f)
  { case "Ar17i": return [18, 17, 20]; }  %  (Ar XVII i)
  { case "Ar17a": return [18, 17, 21]; }  %  (Ar XVII alpha)
  { case "Ar17b": return [18, 17, 22]; }  %  (Ar XVII beta)
  { case "Ar17g": return [18, 17, 23]; }  %  (Ar XVII gamma)
  { case "Ar17d": return [18, 17, 24]; }  %  (Ar XVII delta)
  { case "Ca20a": return [20, 20, 21]; }  %  (Ca XX alpha)
  { case "Ca20b": return [20, 20, 22]; }  %  (Ca XX beta)
  { case "Ca20g": return [20, 20, 23]; }  %  (Ca XX gamma)
  { case "Ca20d": return [20, 20, 24]; }  %  (Ca XX delta)
  { case "Ca19f": return [20, 19, 19]; }  %  (Ca XIX f)
  { case "Ca19i": return [20, 19, 20]; }  %  (Ca XIX i)
  { case "Ca19a": return [20, 19, 21]; }  %  (Ca XIX alpha)
  { case "Ca19b": return [20, 19, 22]; }  %  (Ca XIX beta)
  { case "Ca19g": return [20, 19, 23]; }  %  (Ca XIX gamma)
  { case "Ca19d": return [20, 19, 24]; }  %  (Ca XIX delta)
  { case "Fe26a": return [26, 26, 21]; }  %  (Fe XXVI alpha)
  { case "Fe26b": return [26, 26, 22]; }  %  (Fe XXVI beta)
  { case "Fe26g": return [26, 26, 23]; }  %  (Fe XXVI gamma)
  { case "Fe26d": return [26, 26, 24]; }  %  (Fe XXVI delta)
  { case "Fe25f": return [26, 25, 19]; }  %  (Fe XXV f)
  { case "Fe25i": return [26, 25, 20]; }  %  (Fe XXV i)
  { case "Fe25a": return [26, 25, 21]; }  %  (Fe XXV alpha)
  { case "Fe25b": return [26, 25, 22]; }  %  (Fe XXV beta)
  { case "Fe25g": return [26, 25, 23]; }  %  (Fe XXV gamma)
  { case "Fe25d": return [26, 25, 24]; }  %  (Fe XXV delta)
  { case "Fe1Ka": return [26, 1, 1]; }  %  (Fe I Kalpha)
  { case "Fe24_1062A": return [26, 24, -161758]; }  %  (161758)
  { case "Fe24_679A": return [26, 24, -161756]; }  %  (161756)
  { case "bl_1066A": return NULL; }  %  (161753, 18204) = (Fe XXIV, Fe XVII)
  { case "Fe24_799A": return NULL; }  %  (161759, 161754)
  { case "bl_1102A": return NULL; }  %  (149890, 18163) = (Fe XXIII, Fe XVII)
  { case "bl_1099A": return NULL; }  %  (149893, 131886) = (Fe XXIII, Fe XXII)
  { case "Fe23_830A": return [26, 23, -149914]; }  %  (149914)
  { case "Fe22_1225A": return [26, 22, -131880]; }  %  (131880)
  { case "Fe22_1143A": return [26, 22, -132636]; }  %  (132636)
  { case "Fe22_897A": return [26, 22, -132642]; }  %  (132642)
  { case "Fe22_1193A": return [26, 22, -132890]; }  %  (132890)
  { case "bl_1177A": return NULL; }  %  (132626, 75499) = (Fe XXII, Fe XX)
  { case "Fe22_1149A": return NULL; }  %  (131888, 132634)
  { case "Fe22_873A": return NULL; }  %  (131902, 132644)
  { case "Fe22_786A": return NULL; }  %  (131918, 132676)
  { case "Fe21_1228A": return [26, 21, -128657]; }  %  (128657)
  { case "Fe21_1198A": return [26, 21, -128681]; }  %  (128681)
  { case "Fe21_1304A": return [26, 21, -128653]; }  %  (128653)
  { case "bl_920A": return NULL; }  %  (128775, 75070, 74587) = (Fe XXI, Fe XX, Fe XX)
  { case "Fe21_857A": return NULL; }  %  (128847, 131702, 129682)
  { case "Fe21_1233A": return [26, 21, -131540]; }  %  (131540)
  { case "Fe20_1292A": return NULL; }  %  (75469, 74908)
  { case "Fe20_1286A": return NULL; }  %  (74900, 75472)
  { case "Fe20_1283A": return NULL; }  %  (74354, 74360)
  { case "Fe20_1258A": return NULL; }  %  (74924, 75496)
  { case "Fe20_1000A": return NULL; }  %  (74457, 75036, 74463, 75579)
  { case "Fe20_1297A": return NULL; }  %  (75461, 74351)
  { case "bl_1012A": return NULL; }  %  (75587, 39003, 18189) = (Fe XX, Fe XIX, Fe XVII)
  { case "bl_1301A": return NULL; }  %  (74897, 39144) = (Fe XX, Fe XIX)
  { case "Fe19_1466A": return [26, 19, -39118]; }  %  (39118)
  { case "Fe19_1380A": return [26, 19, -39132]; }  %  (39132)
  { case "Fe19_1364A": return [26, 19, -39124]; }  %  (39124)
  { case "Fe19_1350A": return [26, 19, -38915]; }  %  (38915)
  { case "Fe19_1346A": return [26, 19, -38603]; }  %  (38603)
  { case "Fe19_1342A": return [26, 19, -39134]; }  %  (39134)
  { case "Fe19_1294A": return [26, 19, -38634]; }  %  (38634)
  { case "Fe19_1082A": return [26, 19, -39172]; }  %  (39172)
  { case "Fe19_1013A": return [26, 19, -38692]; }  %  (38692)
  { case "Fe19_986A": return [26, 19, -39223]; }  %  (39223)
  { case "Fe19_1352A": return NULL; }  %  (39128, 38611)
  { case "Fe19_1293A": return NULL; }  %  (38941, 39146)
  { case "Fe18_1453A": return [26, 18, -38000]; }  %  (38000)
  { case "Fe18_1437A": return [26, 18, -37997]; }  %  (37997)
  { case "Fe18_1457A": return [26, 18, -37942]; }  %  (37942)
  { case "Fe18_1562A": return [26, 18, -37995]; }  %  (37995)
  { case "Fe18_1332A": return [26, 18, -37835]; }  %  (37835)
  { case "Fe18_1426A": return NULL; }  %  (37830, 38002)
  { case "Fe18_1421A": return NULL; }  %  (37944, 37998, 38112)
  { case "Fe18_1153A": return NULL; }  %  (37961, 38014)
  { case "Fe18_1133A": return NULL; }  %  (37845, 37963, 38012)
  { case "Fe17_1678A": return [26, 17, -20125]; }  %  (20125)
  { case "Fe17_1526A": return [26, 17, -20128]; }  %  (20128)
  { case "Fe17_1501A": return [26, 17, -20127]; }  %  (20127)
  { case "Fe17_1227A": return [26, 17, -18155]; }  %  (18155)
  { case "Fe17_1212A": return [26, 17, -18151]; }  %  (18151)
  { case "Fe17_1536A": return [26, 17, -25066]; }  %  (25066)
  { case "Fe17_1382A": return [26, 17, -20130]; }  %  (20130)
  { case "bl_1384A": return NULL; }  %  (38918, 74885) = (Fe XIX, Fe XX)
  { case "Al11Ka": return [13, 11, 1]; }  %  (Al XI Kalpha)
  { case "Al10Ka": return [13, 10, 1]; }  %  (Al X Kalpha)
  { case "Al9Ka": return [13, 9, 1]; }  %  (Al IX Kalpha)
  { case "Al8Ka": return [13, 8, 1]; }  %  (Al VIII Kalpha)
  { case "Al7Ka": return [13, 7, 1]; }  %  (Al VII Kalpha)
  { case "Al6Ka": return [13, 6, 1]; }  %  (Al VI Kalpha)
  { case "Al5Ka": return [13, 5, 1]; }  %  (Al V Kalpha)
  { case "Al4Ka": return [13, 4, 1]; }  %  (Al IV Kalpha)
  { case "Al3Ka": return [13, 3, 1]; }  %  (Al III Kalpha)
  { case "Al2Ka": return [13, 2, 1]; }  %  (Al II Kalpha)
  { case "Si12Ka": return [14, 12, 1]; }  %  (Si XII Kalpha)
  { case "Si11Ka": return [14, 11, 1]; }  %  (Si XI Kalpha)
  { case "Si10Ka": return [14, 10, 1]; }  %  (Si X Kalpha)
  { case "Si9Ka": return [14, 9, 1]; }  %  (Si IX Kalpha)
  { case "Si8Ka": return [14, 8, 1]; }  %  (Si VIII Kalpha)
  { case "Si7Ka": return [14, 7, 1]; }  %  (Si VII Kalpha)
  { case "Si6Ka": return [14, 6, 1]; }  %  (Si VI Kalpha)
  { case "Si5Ka": return [14, 5, 1]; }  %  (Si V Kalpha)
  { case "Si4Ka": return [14, 4, 1]; }  %  (Si IV Kalpha)
  { case "Si3Ka": return [14, 3, 1]; }  %  (Si III Kalpha)
  { case "Si2Ka": return [14, 2, 1]; }  %  (Si II Kalpha)
  { case "Ar16Ka": return [18, 16, 1]; }  %  (Ar XVI Kalpha)
  { case "Ar15Ka": return [18, 15, 1]; }  %  (Ar XV Kalpha)
  { case "Ar14Ka": return [18, 14, 1]; }  %  (Ar XIV Kalpha)
  { case "Ar13Ka": return [18, 13, 1]; }  %  (Ar XIII Kalpha)
  { case "Ar12Ka": return [18, 12, 1]; }  %  (Ar XII Kalpha)
  { case "Ar11Ka": return [18, 11, 1]; }  %  (Ar XI Kalpha)
  { case "Ar10Ka": return [18, 10, 1]; }  %  (Ar X Kalpha)
  { case "Ar9Ka": return [18, 9, 1]; }  %  (Ar IX Kalpha)
  { case "Ar8Ka": return [18, 8, 1]; }  %  (Ar VIII Kalpha)
  { case "Ar7Ka": return [18, 7, 1]; }  %  (Ar VII Kalpha)
  { case "Ar6Ka": return [18, 6, 1]; }  %  (Ar VI Kalpha)
  { case "Ar5Ka": return [18, 5, 1]; }  %  (Ar V Kalpha)
  { case "Ar4Ka": return [18, 4, 1]; }  %  (Ar IV Kalpha)
  { case "Ar3Ka": return [18, 3, 1]; }  %  (Ar III Kalpha)
  { case "Ar2Ka": return [18, 2, 1]; }  %  (Ar II Kalpha)
  { message("error ("+_function_name()+"): line "+line+" is unknown."); return; }
}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
private define _get_lambda_parameters_of_lines()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
{
  variable ids=1, lMin=get_plot_options().xmin, lMax=get_plot_options().xmax, all=0;
  switch(_NARGS)
  { case 0: ; }
  { case 1: ids = (); }
  { case 2: (lMin, lMax) = (); }
  { case 3: (ids, lMin, lMax) = (); }
  { case 4: (ids, lMin, lMax, all) = (); }
  { return; }

  if(lMin>lMax) { (lMin, lMax) = (lMax, lMin); }

  variable par_ids = Integer_Type[0];
  variable par_info, par_infos = get_params();
  foreach par_info (par_infos)
  {
    variable id;
    foreach id ([ids])
    {
      if(    string_match(par_info.name, "^lines("+string(id)+")\..*_lam", 1)
         && ((lMin <= par_info.min <= lMax) or (lMin<=par_info.max<=lMax))
         && (all || get_par(par_info.index+1)!=0)
        )
      { par_ids = [par_ids, par_info.index]; }
    }
  }
  if(length(par_ids)==0) { return NULL; }

  return par_ids[ array_sort(par_ids, &compare_pars) ];
}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define get_lambda_parameters_of_lines()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{get_lambda_parameters_of_lines}
%!%-
{
  variable ids=1, lMin=get_plot_options().xmin, lMax=get_plot_options().xmax;
  switch(_NARGS)
  { case 0: ; }
  { case 1: ids = (); }
  { case 2: (lMin, lMax) = (); }
  { case 3: (ids, lMin, lMax) = (); }
  { help(_function_name()); return; }

  return _get_lambda_parameters_of_lines(ids, lMin, lMax, 0);
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define get_lambda_parameters_of_all_lines()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{get_lambda_parameters_of_all_lines}
%!%-
{
  variable ids=1, lMin=get_plot_options().xmin, lMax=get_plot_options().xmax;
  switch(_NARGS)
  { case 0: ; }
  { case 1: ids = (); }
  { case 2: (lMin, lMax) = (); }
  { case 3: (ids, lMin, lMax) = (); }
  { help(_function_name()); return; }

  return _get_lambda_parameters_of_lines(ids, lMin, lMax, 1);
}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define get_lambda_parameters_of_lines_from_one_ion(ion)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{get_lambda_parameters_of_lines_from_one_ion}
%!%-
{
 return get_lambda_parameters_of_lines[where(array_map(Char_Type, &string_match, array_struct_field( get_params(get_lambda_parameters_of_lines), "name"), ion, 1) )];
}


%%%%%%%%%%%%%%%%%%%%%
define list_all_lines()
%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{lists_all_lines}
%\synopsis{shows the parameters of a lines-model's lines in a given wavelength range}
%\usage{list_all_lines([ids][, lMin, lMax]);}
%\seealso{lines, get_lambda_parameters_of_all_lines, list_lines}
%!%-
{
  variable ids=1, lMin=get_plot_options().xmin, lMax=get_plot_options().xmax;
  switch(_NARGS)
  { case 0: ; }
  { case 1: ids = (); }
  { case 2: (lMin, lMax) = (); }
  { case 3: (ids, lMin, lMax) = (); }
  { help(_function_name()); return; }

  variable par_ids = get_lambda_parameters_of_all_lines(ids, lMin, lMax);
  variable par_id, first=1;
  foreach par_id (par_ids)
  { if(first) { first = 0; } else { message(""); }
    list_Par( par_id+[0,1,2] );
  }
}


%%%%%%%%%%%%%%%%%
define list_lines()
%%%%%%%%%%%%%%%%%
%!%+
%\function{list_lines}
%\synopsis{shows the parameters of a lines-model's used lines in a given wavelength range}
%\usage{list_lines([ids][, lMin, lMax]);}
%\seealso{lines, get_lambda_parameters_of_lines, list_all_lis}
%!%-
{
  variable ids=Integer_Type[0], lMin=get_plot_options().xmin, lMax=get_plot_options().xmax;
  switch(_NARGS)
  { case 0: ; }
  { case 1: ids = (); }
  { case 2: (lMin, lMax) = (); }
  { case 3: (ids, lMin, lMax) = (); }
  { help(_function_name()); return; }

  if(length(ids)==0)
  {
    variable ff = get_fit_fun();
    forever
    {
      variable m = string_matches(ff, `lines(\([0-9]*\))\(.*\)`);
      if(m==NULL)  break;
      ids = [ids, integer(m[1])];
      ff = m[2];
    }
  }

  variable par_ids = get_lambda_parameters_of_lines(ids, lMin, lMax);
  variable par_id, first=1;
  foreach par_id (par_ids)
  { if(first) { first = 0; } else { message(""); }
    list_Par( par_id+[0,1,2] );
  }
}


%%%%%%%%%%%%%%%%%%%%%%
define get_line_labels()
%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{get_line_labels}
%\qualifiers{
%\qualifier{label_Ly_He}{ [=1]}
%\qualifier{print_list}{}
%}
%\seealso{lines}
%!%-
{
  variable lambdas = Double_Type[0], labels = String_Type[0], Z = Char_Type[0], ion = Char_Type[0], nr = Char_Type[0];

  foreach ( get_lambda_parameters_of_lines() )
  { variable line = ();
    line = string_matches(get_par_info(line).name, `lines([0-9]+)\.\(.*\)_lam`)[1];
    variable tr = get_line_transition( line );
    variable lab;
    if(tr!=NULL)
    {
      Z   = [Z,   tr[0]];
      ion = [ion, tr[1]];
      nr  = [nr,  tr[2]];
      if(tr[2]>0)
      {
        lab = sprintf("%s %s %s", atom_name(tr[0]), Roman(tr[1]), ext_line_type(tr[2], 1));
        switch(tr[1])
        { case tr[0]:
            if(qualifier("label_Ly_He", 1))
            { lab = sprintf("%s Ly %s", atom_name(tr[0]), ext_line_type(tr[2], 1)); }
        }
        { case (tr[0]-1):
            if(qualifier("label_Ly_He", 1))
            { lab = sprintf("%s He %s", atom_name(tr[0]), ext_line_type(tr[2], 1)); }
        }
      }
      else
      { lab = sprintf("%s %s", atom_name(tr[0]), Roman(tr[1])); }
    }
    else
    {
      lab = string_matches(line, `\([a-zA-Z0-9]+\)`)[1];
      Z   = [Z,   -1];
      ion = [ion, -1];
      nr  = [nr,  -1];
      if(lab == "bl")
        lab = "blend";
      else
        lab = string_matches(lab, `\([a-zA-Z]+\)`)[1] + " " + Roman( integer(string_matches(lab, `\([0-9]+\)`)[1]) );
    }

    lambdas = [lambdas, mean(get_line_lambdas(line))];
    labels  = [labels,  lab];
  }

  if(qualifier_exists("print_list"))
  { _for $1 (0, length(lambdas)-1, 1)
    { ()=printf(" { %.4f, \"%s\", %d, %d, %d },\n", lambdas[$1], labels[$1], Z[$1], ion[$1], nr[$1]); }
  }
  else
    return lambdas, labels;
}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%
define Doppler_velocity()
%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{Doppler_velocity}
%\synopsis{calculates a Doppler velocity shift from a wavelength and the rest wavelength}
%\usage{Double_Type v = Doppler_velocity(Double_Type lambda, Double_Type lambda0);}
%\description
%    \code{v = (lambda-lambda0)/lambda_0 * c;  %} speed of light \code{c = 299792} km/s
%\seealso{get_line_velocity}
%!%-
{
  variable lambda, lambda0;
  switch(_NARGS)
  { case 2: (lambda, lambda0) = (); }
  { help(_function_name()); return; }

   return (lambda/lambda0-1)*299792.;
}


%%%%%%%%%%%%%%%%%%%%%%%
define get_line_velocity()
%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{get_line_velocity}
%\synopsis{calculates the velocity shift in a line of the lines-model}
%\usage{Double_Type v = get_line_velocity([Integer_Type i,] String_Type line);}
%\description
%    \code{lambda = get_par("lines(i).line_lam");}\n
%    \code{lambda0 = mean( get_line_lambdas(line) );}\n
%    \code{v = (lambda-lambda0)/lambda_0 * c;  %} speed of light \code{c = 299792} km/s
%\seealso{Doppler_velocity}
%!%-
{
  variable i=1, line;
  switch(_NARGS)
  { case 1: line = (); }
  { case 2: (i, line) = (); }
  { help(_function_name()); return; }

  variable parameter_name = "lines(" + string(i) + ")." + line  + "_lam";
  if( howmany(array_struct_field(get_params(), "name")==parameter_name) == 0 )  { vmessage("error (%s): line %s does not exist within the current model", _function_name(), line); return NULL; }
  variable lambda = get_par(parameter_name);
  variable lambda0 = mean( get_line_lambdas(line) );
  return (lambda/lambda0-1)*299792.;
}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define get_column_density_from_line()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{get_column_density_from_line}
%\synopsis{}
%\usage{Double_Type N = get_column_density_from_line([Integer_Type i,] String_Type line);}
%\description
%     N  =  mc^2/[pi e^2] * W_lambda / [f_lu * lambda^2];\n
%        =  1.13e17/cm^2 * (W_lambda/mA) / [f_lu * (lambda/A)^2]\n
%                                        %  f_lu = mc / [8 pi^2 e^2] * lambda^2 * g_u / g_l * A_ul\n
%                                        %       = 1.4992e-16 * (lambda/A)^2 * g_u / g_l * (A_ul/s^{-1})\n
%!%-
{
  variable i=1, line;
  switch(_NARGS)
  { case 1: line = (); }
  { case 2: (i, line) = (); }
  { help(_function_name()); return; }

  variable parameter_name = "lines("+string(i)+")."+line+"_EW";
  if( howmany(array_struct_field(get_params(), "name")==parameter_name) == 0 )  { vmessage("error (%s): %s does not exist within the current model", _function_name(), line); return NULL; }
  variable EW = get_par("lines("+string(i)+")."+line+"_EW");
  if(EW>=0) { vmessage("warning (%s): %s (#%d) is not an absorption line", _function_name(), line, i); return 0; }
  variable transition = get_line_transition(line);
  if(transition == NULL)  { vmessage("warning (%s): transition(s) causing %s unknown", _function_name(), line); return NULL; }
  variable info = ext_line_info(transition[0], transition[1], transition[2]);
  if(info.gf == NULL)  { vmessage("warning (%s): atomic-data of %s unknown", _function_name(), line); return NULL; }
  variable lambda0 = info.lambda;
  variable f_ij = info.gf/info.g_low;
  return -1.13e17/f_ij/lambda0^2 * EW;
}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%
define HeTriplet_fit(bin_lo, bin_hi, par)
%%%%%%%%%%%%%%%%%%%%
{
  return 0*bin_lo;  % additive dummy-model
}

%%%%%%%%%%%%%%%%%%%%
define HeTriplet_defaults(i)
%%%%%%%%%%%%%%%%%%%%
{
  switch(i)
  { case 0: return (1.5, 0, 0, 5); }
  { case 1: return (1.5, 0, 0, 5); }
}

add_slang_function("HeTriplet", ["Mg11_R", "S15_R"]);
set_param_default_hook("HeTriplet", "HeTriplet_defaults");


%%%%%%%%%%%%%%%%%%%%
define use_HeTriplet(id, ion)
%%%%%%%%%%%%%%%%%%%%
{
  id = "(" + string(id) + ")." + ion;
  variable i = get_par("lines" + id + "i_EW");
  if(i!=0) { set_par("HeTriplet" + id + "_R",  get_par("lines" + id + "f_EW") / i); }  % R = f/i
  set_par("lines" + id + "f_EW",  "lines" + id + "i_EW * HeTriplet" + id + "_R");      % f = i * R
}
