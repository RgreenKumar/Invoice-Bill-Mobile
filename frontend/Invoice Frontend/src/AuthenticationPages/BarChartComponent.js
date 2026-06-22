// import React from 'react';
// import ReactApexChart from 'react-apexcharts';

// function BarChartComponent({quizScores}) {
//   let quizNames = [];
//     let scores = [];

//     if (Array.isArray(quizScores) && quizScores.length > 0) {
//         quizNames = quizScores.map((quiz) => {
//             return quiz && quiz.quizzName ? quiz.quizzName : 'Unknown Quiz';
//         });

//         scores = quizScores.map((quiz) => {
//             return quiz && quiz.score !== undefined ? quiz.score : 0;
//         });
//     } else {
//         // Provide default values when quizScores is empty or invalid
//         quizNames = ['No Data'];
//         scores = [0];
//     }

//   const chartData = {
//     series: [
//       {
//         name: 'Score',
//         data: scores,
//       },
//     ],
//     options: {
//       chart: {
//         type: 'bar',
//         toolbar: { // Add this toolbar object
//             show: false, // Disable the toolbar
//           },
//       },
//       plotOptions: {
//         bar: {
//           horizontal: false,
//           columnWidth: '60%', // Increased columnWidth
//           endingShape: 'rounded',
//         },
//       },
//       dataLabels: {
//         enabled: true,
//         formatter: (val) => val?.toFixed(0),
//       },
//       stroke: {
//         show: true,
//         width: 2,
//         colors: ['transparent'],
//       },
//       xaxis: {
//         categories: quizNames,
//         labels: {
//           hideOverlappingLabels: false,
//         },
//       },
//       fill: {
//         opacity: 1,
//       },
//       tooltip: {
//         y: {
//           formatter: function (val) {
//             return val;
//           },
//         },
//       },
//       colors: ['#9CCC65'],
//     },
//   };

//   return (
//     <div className="chart-container">
//         <ReactApexChart
//           options={chartData.options}
//           series={chartData.series}
//           type="bar"
//           width="100%"
//         />
//       </div>
//   );
// }

// export default BarChartComponent;