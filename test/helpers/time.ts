// const duration = {
//   seconds: function (val: number) {
//       return val;
//   },
//   minutes: function (val: number) {
//       return val * this.seconds(60);
//   },
//   hours: function (val: number) {
//       return val * this.minutes(60);
//   },
//   days: function (val: number) {
//       return val * this.hours(24);
//   },
//   months: function (val: number) {
//     return val * this.days(31);
//   },
// }

export module duration {
  export function seconds (val: number) {
    return val;
  }
  export function minutes (val: number) {
    return val * seconds(60);
  }
  export function hours (val: number) {
    return val * minutes(60);
  }
  export function days (val: number) {
    return val * hours(24);
  }
  export function months (val: number) {
  return val * days(31);
  }
};
