// import React, { useState, useEffect } from "react";
// import { CircularProgressbarWithChildren, buildStyles } from "react-circular-progressbar";
// import "react-circular-progressbar/dist/styles.css";

// const RadialProgressBar = ({ percentage, total }) => {
//   const circleRatio = 0.7;
//   const [progress, setProgress] = useState(0); // State to track progress

//   useEffect(() => {
//     // Animate the progress value over 2 seconds
//     const targetValue = percentage;
//     let startTime = null;

//     const animateProgress = (timestamp) => {
//       if (!startTime) startTime = timestamp;
//       const elapsed = timestamp - startTime;

//       // Calculate the new progress value based on elapsed time
//       const newProgress = Math.min((elapsed / 2000) * targetValue, targetValue); // 2000 ms = 2 seconds
//       setProgress(newProgress);

//       // Continue the animation until 3 seconds
//       if (elapsed < 2000) {
//         requestAnimationFrame(animateProgress);
//       }
//     };

//     // Start the animation
//     requestAnimationFrame(animateProgress);
//   }, [percentage]); // Run the effect when percentage changes

//   return (
//     <div style={{ width: "100%", height: "100%", transform: "rotate(-125deg)" }}>
//       <CircularProgressbarWithChildren
//         value={progress} // Bind the progress state to the value
//         strokeWidth={12}
//         circleRatio={circleRatio}
//         styles={buildStyles({
//           strokeLinecap: "round", // Rounded ends
//           pathColor: "url(#gradient)", // Gradient fill
//           trailColor: "#e0e0e0", // Background color for unfilled part
//           textColor: "black", // Optional: set text color
//         })}
//       >
//         {/* Gradient Definition */}
//         <svg style={{ height: 0 }}>
//           <defs>
//             <linearGradient id="gradient" gradientTransform="rotate(90)">
//               <stop offset="0%" stopColor="#4A00E0" />
//               <stop offset="50%" stopColor="#8E2DE2" />
//               <stop offset="100%" stopColor="#C33764" />
//             </linearGradient>
//           </defs>
//         </svg>
//         {/* Center Text */}
//         <h5 style={{ transform: "rotate(125deg)" }}>{total}</h5>
//       </CircularProgressbarWithChildren>
//     </div>
//   );
// };

// export default RadialProgressBar;
